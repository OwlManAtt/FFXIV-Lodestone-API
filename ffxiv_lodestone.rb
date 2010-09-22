require 'rubygems'
require 'nokogiri'
require 'open-uri'

module FFXIVLodestone
  class Character
    class StatList
      include Enumerable 
      attr_reader :stats

      def initialize(table)
        @stats = {}
        
        table.search('tr').each do |tr|
          @stats[tr.children[0].content.strip.downcase.to_sym] = tr.children[2].content.gsub("\302\240",' ').split(' ')[0].to_i
        end
      end

      def each
        @stats.each {|stat| yield stat}
      end

      def method_missing(method)
        return @stats[method] if @stats.key? method
        super
      end
    end # StatList

    class SkillList
      class Skill
        attr_reader :name, :skill_name, :rank, :current_skill_points, :skillpoint_to_next_level

        def initialize(job,skill_name,rank,cur_sp,skillup_sp)
          @name = job 
          @skill_name = skill_name
          @rank = rank
          @current_skill_points = cur_sp
          @skillpoint_to_next_level = skillup_sp
        end # initalize
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
            current_sp = sp.split('/')[0].strip
            levelup_sp = sp.split('/')[1].strip
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
      
      def method_missing(method)
        return @skills[method] if @skills.key? method
        super
      end

    end # FFXIVLodestone::Character::SkillList

    attr_reader :skills, :stats, :resistances
    def initialize(character_id)
      # TODO exception if ID isn't an integer
      # TODO exception if we don't have a valid char ID
      @character_id = character_id

      doc = Nokogiri::HTML(open("http://lodestone.finalfantasyxiv.com/rc/character/status?cicuid=#{@character_id}", {'Accept-Language' => 'en-us,en;q=0.5', 'Accept-Charset' => 'utf-8;q=0.5'}))

      # The skills table doesn't have a unqiue ID or class to find it by, so take the first skill lable and go up two elements (table -> tr -> th.mianskill-lable)
      @skills = SkillList.new(doc.search('th.mainskill-label').first.parent.parent)
      @stats = StatList.new(doc.search("div.contents-subheader[contains('Attributes')]").first.next_sibling.next_sibling)
      @resistances = StatList.new(doc.search("div.contents-subheader[contains('Elements')]").first.next_sibling.next_sibling)
    end

  end # character
end # end FFXIVLodestone
