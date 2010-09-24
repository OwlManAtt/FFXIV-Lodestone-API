require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'

module FFXIVLodestone
  VERSION = '0.8.1'

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
    def to_h
      to_hash
    end
  end

  class Character
    class NotFoundException < RuntimeError 
    end

    class StatList < Hash
      def initialize(table)
        table.search('tr').each do |tr|
          self[tr.children[0].content.strip.downcase.to_sym] = tr.children[2].content.gsub("\302\240",' ').split(' ')[0].to_i
        end
      end

      def stats
	      self
      end
    end # StatList

    class SkillList
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

      def initialize(skill_table)
        @skills = {}

        skill_table.children.each do |skill|
          name = skill.children[0].children[1].content
          if SKILL_TO_CLASS.key? name
            key = SKILL_TO_CLASS[name]
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
            sp.gsub!("\302\240",'') # this is a &nbsp but it looks ugly in #inspect(), so remove it.
            current_sp = sp.split('/')[0].strip.to_i
            levelup_sp = sp.split('/')[1].strip.to_i
          end

          @skills[key] = Skill.new(job,name,rank,current_sp,levelup_sp)
        end
      end # initialize

      # Lists all leveled jobs.
      def list
        list = []
        @skills.each do |name,skill| 
          list << skill if skill.rank > 0
        end

        return list
      end

      def to_h
        list = {}
        @skills.each {|job,data| list[job] = data.to_h}

        return list
      end
      
      def method_missing(method)
        return @skills[method] if @skills.key? method
        super
      end

    end # FFXIVLodestone::Character::SkillList

    attr_reader :skills, :stats, :resistances, :profile
    def initialize(character_id)
      @character_id = character_id

      doc = Nokogiri::HTML(get_html(@character_id))

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
      profile = doc.search('#profile-plate2')
      profile.search('tr th').each do |th|
        key = th.content.strip.downcase.gsub(':','').gsub(' ','_').to_sym
        value = th.next_sibling.next_sibling.content.strip.gsub("\302\240",'')

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
      race_line = profile.search('tr td').first.content.strip.gsub("\302\240",' ').split(' / ')
      @profile[:race] = race_line.pop

      # horrible array splitting and popping trix. hidoi hidoi!
      race_line = race_line.first.split ' '
      @profile[:gender] = race_line.pop
      @profile[:clan] = race_line.join ' '
    end
    
    def name
      "#{@profile[:first_name]} #{@profile[:last_name]}"
    end

    def to_json
      data = {}
      data.merge!(@profile)
      data[:jobs] = @skills.to_h
      data[:attributes] = @stats.to_h
      data[:resistances] = @resistances.to_h

      data.to_json
    end

    def method_missing(method)
      return @profile[method] if @profile.key? method
      super
    end

    protected 

    # This method can be redefined in a test class.
    def get_html(id)
      open("http://lodestone.finalfantasyxiv.com/rc/character/status?cicuid=#{id}", {'Accept-Language' => 'en-us,en;q=0.5', 'Accept-Charset' => 'utf-8;q=0.5'})
    end
  end # character
end # end FFXIVLodestone
