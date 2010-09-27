require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'

# Nokogiri changes &nbsp; entities to \302\240. This may be OK in most instances,
# but at the very least, it makes #inspect() look like shit, which is a headache
# for people trying to troubleshoot.
class String
  def strip_nbsp
    self.strip.gsub("\302\240",' ')
  end

  def strip_nbsp!
    before = self.reverse.reverse
    self.strip!
    self.gsub!("\302\240",' ')
    before == self ? nil : self
  end
end

module FFXIVLodestone
  # Gem version.
  VERSION = '0.9.5'

  # Accept-language must be sent; their default is Japanese text.
  HTTP_OPTIONS = {'Accept-Language' => 'en-us,en;q=0.5', 'Accept-Charset' => 'utf-8;q=0.5', 
    'User-Agent' => "ffxiv-lodestone-#{FFXIVLodestone::VERSION} (Ruby/#{RUBY_VERSION})"}
  
  # Search page server IDs.
  SERVER_SEARCH_INDEXES = {:cornelia => 2, :kashuan => 3, :gysahl => 4, :mysidia => 5, 
  :istory => 6, :figaro => 7, :wutai => 8, :trabia => 9, :lindblum => 10, :besaid => 11,
  :selbina => 12, :rabanastre => 13, :bodhum => 14, :melmond => 15, :palamecia => 16,
  :saronia => 17, :fabul => 18}
  
  # Alias the stupid names in Lodestone to class names. 
  SKILL_TO_CLASS = {
    'Hand-to-Hand' => :pugilist,
    'Sword' => :gladiator,
    'Axe' => :marauder,
    'Archery' => :archer,
    'Polearm' => :lancer,
    'Thaumaturgy' => :thaumaturge,
    'Conjury' => :conjurer,
    'Woodworking' => :carpenter,
    'Smithing' => :blacksmith,
    'Armorcraft' => :armorer,
    'Goldsmithing' => :goldsmith,
    'Leatherworking' => :leatherworker,
    'Clothcraft' => :weaver,
    'Alchemy' => :alchemist,
    'Cooking' => :culinarian,
    'Mining' => :miner,
    'Botany' => :botanist,
    'Fishing' => :fisher,
  }

  module Serializable
    def to_yaml_properties
      serialize_properties.map {|sym| "@%s" % sym }
    end

    def to_hash
      serialize_properties.reduce(Hash.new) {|h,sym|
        h[sym] = self.send(sym)
        h
      }
    end
    alias :to_h :to_hash # legacy API

    def to_json(args={})
      self.to_hash.to_json
    end
  end

  # Represents an FFXIV character. Example:
  #
  #   FFXIVLodestone::Character.new(1015990)
  class Character
    class NotFoundException < RuntimeError 
    end

    class AmbiguousNameError < RuntimeError
    end

    class StatList < Hash
      def initialize(table)
        table.search('tr').each do |tr|
          self[tr.children[0].content.strip.downcase.to_sym] = tr.children[2].content.strip_nbsp.split(' ')[0].to_i
        end
      end

      def method_missing(method)
        return self[method] if self.key? method
        super
      end
    end # StatList

    class SkillList < Hash 
      class Skill
        include Serializable

        attr_reader :name, :skill_name, :rank, :current_skill_points, :skillpoint_to_next_level
        def initialize(job,skill_name,rank,cur_sp,skillup_sp)
          @name = job 
          @skill_name = skill_name
          @rank = rank
          @current_skill_points = cur_sp
          @skillpoint_to_next_level = skillup_sp
        end # initalize

        def serialize_properties
          [:name, :skill_name, :rank, :current_skill_points, :skillpoint_to_next_level]
        end
      end # Skill
      
      def initialize(skill_table)
        @skills = {}

        skill_table.children.each do |skill|
          name = skill.children[0].children[1].content
          if FFXIVLodestone::SKILL_TO_CLASS.key? name
            key = FFXIVLodestone::SKILL_TO_CLASS[name]
            job = key.to_s.capitalize
          else
            key = name.gsub('-', '_').downcase.to_sym
            job = name
          end

          # '-' = not leveled (never equipped the class' weapon)
          rank = skill.children[2].search('table tr td[last()]').children.first.content
          rank = (rank.include?('-') ? 0 : rank.to_i)

          # # '-' = not leveled, otherwise it will be in the format '391 / 1500'
          sp = skill.children[4].search('table tr td[last()]').children.first.content

          if sp.include? '-'
            current_sp = 0
            levelup_sp = 0
          else
            sp.strip_nbsp!
            current_sp = sp.split('/')[0].strip.to_i
            levelup_sp = sp.split('/')[1].strip.to_i
          end

          self[key] = Skill.new(job,name,rank,current_sp,levelup_sp)
        end
      end # initialize

      # Lists all leveled (rank > 0) jobs.
      def levelled 
        self.keys.reduce(Array.new) do |a,key| 
          a << self.send(key) if self.send(key).rank > 0
          a
        end
      end

      def method_missing(method)
        return self[method] if self.key? method
        super
      end
    end # FFXIVLodestone::Character::SkillList

    attr_reader :skills, :stats, :resistances, :profile
    alias :jobs :skills
    def initialize(args={})
      args = {:id => args} unless args.class == Hash
      raise ArgumentError, 'No search paremeters were given.' if args.empty?

      if args.key? :id
        character_id = args[:id]
        raise ArgumentError, 'No other arguments may be specified in conjunction with :id.' if args.size > 1
      else
        characters = Character.search(args)
        raise NotFoundException, 'Character search yielded no results.' if characters.empty?
        raise AmbiguousNameError, 'Multiple characters matched that name.' if characters.size > 1
        character_id = characters.first[:id]
      end
      
      @character_id = character_id
      doc = Nokogiri::HTML(Character.get_profile_html(@character_id))

      # Did we get an error page? Invalid ID, etc.
      if !((doc.search('head title').first.content.match /error/i) == nil)
        raise NotFoundException, 'Bad character ID or Lodestone is broken.' 
      end

      # The skills table doesn't have a unqiue ID or class to find it by, so take the first skill lable and go up two elements (table -> tr -> th.mianskill-lable)
      @skills = SkillList.new(doc.search('th.mainskill-label').first.parent.parent)
      @stats = StatList.new(doc.search("div.contents-subheader[contains('Attributes')]").first.next_sibling.next_sibling)
      @resistances = StatList.new(doc.search("div.contents-subheader[contains('Elements')]").first.next_sibling.next_sibling)
      
      # The character info box at the top ... actually has a useful ID!
      @profile = {}
      profile = doc.search("//div[starts-with(@id,'profile-plate')]") 
      profile.search('tr th').each do |th|
        key = th.content.strip.downcase.gsub(':','').gsub(' ','_').to_sym
        value = th.next_sibling.next_sibling.content.strip_nbsp

        # HP/MP/TP are max values. They depend on the currently equipped job and are not very
        # meaningful pieces of data. XP will be handled seperately. 
        unless [:hp, :mp, :tp, :experience_points].include? key
          @profile[key] = value 
        end

        if key == :experience_points
          @profile[:current_exp] = value.split('/')[0].to_i
          @profile[:exp_to_next_level] = value.split('/')[1].to_i
        end
      end
      
      # Fix this datatype.
      @profile[:physical_level] = @profile[:physical_level].to_i
      
      # Parse the character name/world line...
      name_line = profile.search('#charname').first.content.gsub(')','').strip.split(' (')
      @profile[:world] = name_line[1]
      @profile[:first_name] = name_line[0].split(' ')[0]
      @profile[:last_name] = name_line[0].split(' ')[1]

      # Parse the "Seeker of the Sun Female / Miqo'te" line... fun~
      race_line = profile.search('tr td').first.content.strip_nbsp.split(' / ')
      @profile[:race] = race_line.pop

      # horrible array splitting and popping trix. hidoi hidoi!
      race_line = race_line.first.split ' '
      @profile[:gender] = race_line.pop
      @profile[:clan] = race_line.join ' '

      @profile.merge! generate_portrait_urls(doc.search('div.image-mount-image img').first.attr('src').strip)

      @profile[:character_id] = @character_id.to_i
    end

    # FFXIVLodestone::Character.search(:name => 'Character Name', :world => 'Server') => Array
    def self.search(args={})
      raise ArgumentError, 'Search parameters must be hash.' unless args.class == Hash
      raise ArgumentError, ':name must be specified to use search.' unless args.key? :name

      world_id = nil
      if args.key? :world
        # :world can be passed as a string ('Figaro') or as the integer used by the search page (7).
        # This is so the library is not completely useless when new worlds are added - developers can
        # fall back to the integers until the gem is updated.
        if args[:world].class == String
          raise ArgumentError, 'Unknown world server.' unless FFXIVLodestone::SERVER_SEARCH_INDEXES.key? args[:world].downcase.to_sym 

          world_id = FFXIVLodestone::SERVER_SEARCH_INDEXES[args[:world].downcase.to_sym] 
        else
          world_id = args[:world].to_i # force it to an int to prevent any funny business.
        end
      end

      doc = Nokogiri::HTML(get_search_html(args[:name],world_id))
      results = doc.search("table.contents-table1 tr th[contains('Character Name')]")
      return [] if results.empty? # No results = no results table header. 
      
      results = results.last.parent.parent
      results.children.first.remove # discard the table headers
      
      results.children.map do |tr|
        name_element = tr.search('td:first table tr td:last a').first
        {
          :id => name_element.attr('href').gsub('/rc/character/top?cicuid=','').strip.to_i,
          :name => name_element.content.strip,
          :portrait_thumb_url => tr.search('td:first table tr td:first img').first.attr('src').strip,
          :world => tr.search('td:last').last.content.strip
        }
      end
    end # search
    
    # Returns first name / last name seperated by a space.
    def name
      "#{@profile[:first_name]} #{@profile[:last_name]}"
    end

    def to_json(args={})
      data = {}
      data.merge!(@profile)
      data[:jobs] = @skills
      data[:attributes] = @stats
      data[:resistances] = @resistances

      data.to_json
    end

    def method_missing(method)
      return @profile[method] if @profile.key? method
      super
    end

    protected 
    # This method can be redefined in a test class.
    def self.get_profile_html(id)
      open("http://lodestone.finalfantasyxiv.com/rc/character/status?cicuid=#{id}", FFXIVLodestone::HTTP_OPTIONS)
    end

    # Another method to redefine in the test file...
    def self.get_search_html(name,world_id)
      open(URI.encode("http://lodestone.finalfantasyxiv.com/rc/search/search?tgt=77&q=#{name}&cw=#{world_id}&num=40"), FFXIVLodestone::HTTP_OPTIONS)
    end

    def generate_portrait_urls(url)
      url_list = {}

      a = URI.parse(url)
      a.query = nil
      url_list[:portrait_url] = a.to_s

      a.path = a.path.gsub(/\/([A-Z0-9]+)_m_/i,'/\1_ss_')
      url_list[:portrait_thumb_url] = a.to_s

      return url_list
    end
  end # character
end # end FFXIVLodestone
