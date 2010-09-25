$:.unshift("#{File.expand_path(File.dirname(__FILE__))}/../lib")
require 'bacon'
require 'ffxiv-lodestone'

# Make the character class open our saved HTML...
class FFXIVLodestone::Character
  def self.get_profile_html(id)
    open("./characters/#{id}.html")
  end

  def self.get_search_html(character,world_id)
    n = character.downcase.gsub(' ','-')
    open("./searches/#{n}_#{world_id}.html")
  end
end

describe 'Character(invalid)' do 
  it 'is an invalid id' do
    should.raise(FFXIVLodestone::Character::NotFoundException) { FFXIVLodestone::Character.new('invalid') }
  end

  it 'is a bad argument list' do
    should.raise(ArgumentError) { FFXIVLodestone::Character.new(:id => 1, :name => 'Ayeron Lifebloom', :world => 'Figaro') }
    should.raise(ArgumentError) { FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom') }
    should.raise(ArgumentError) { FFXIVLodestone::Character.new(:world => 'Figaro') }
  end

  it 'is a bad world' do
    should.raise(ArgumentError) { FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom', :world => 'FAKESERVER') }
  end

  it 'is an ambiguous name' do
    should.raise(FFXIVLodestone::Character::AmbiguousNameError) { FFXIVLodestone::Character.new(:name => 'Lady', :world => 'Selbina') }
  end

  it 'should actually work' do
    should.not.raise(ArgumentError) { FFXIVLodestone::Character.new(:id => 1015990) }
    should.not.raise(ArgumentError) { FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom', :world => 'Figaro') }
  end
end

describe "Character(:name => 'Lady Simmons', :world => 'Selbina')" do
  it 'should find the character' do
    char = FFXIVLodestone::Character.new(:name => 'Lady Simmons', :world => 'Selbina')
    char.name.should.equal 'Lady Simmons'
    char.character_id.should.equal 1015990

    char = FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom', :world => 'Figaro')
    char.name.should.equal 'Ayeron Lifebloom'
    char.character_id.should.equal 1502635
    char.physical_level.should.equal 12

    char = FFXIVLodestone::Character.new(:id => 2172370)
    char.name.should.equal 'Karen Kranfel'
    char.character_id.should.equal 2172370
  end
end

describe 'Character(1015990)' do
  before do
    @char = FFXIVLodestone::Character.new(1015990)
  end

  it 'should have profile data' do
    @char.character_id.should.equal 1015990
    @char.name.should.equal 'Lady Simmons'
    @char.world.should.equal 'Selbina'
    @char.physical_level.should.equal 12
    @char.exp_to_next_level.should.equal 28000
    @char.current_exp.should.equal 18880 
    @char.gender.should.equal 'Female'
    @char.race.should.equal "Miqo'te"
    @char.clan.should.equal 'Seeker of the Sun'
  end

  it 'should have stat lists' do
    stats = {:strength => 16, :vitality => 24, :dexterity => 17, :intelligence => 36, :mind => 37, :piety => 28}
    resists = {:fire => 28, :water => 29, :lightning => 30, :wind => 30, :earth => 25, :ice => 15}
    
    @char.stats.should.equal stats
    @char.stats.strength.should.equal 16

    @char.resistances.should.equal resists 
    @char.resistances.fire.should.equal 28
  end

  it 'should have job data' do
    @char.skills.carpenter.rank.should.equal 5
    @char.skills.carpenter.current_skill_points.should.equal 305 
    @char.skills.carpenter.skillpoint_to_next_level.should.equal 1500
  end

  it 'should list all leveled jobs' do
    @char.skills.levelled.map(&:name).sort.should.equal ['Conjurer','Carpenter','Leatherworker','Weaver','Alchemist','Miner','Botanist','Fisher'].sort
  end

  it 'should be convertable to json' do
    json = <<LOLHEREDOC
{"first_name":"Lady","character_id":1015990,"nameday":"4th Sun of the 3rd Umbral Moon","world":"Selbina","last_name":"Simmons","attributes":{"vitality":24,"dexterity":17,"intelligence":36,"mind":37,"piety":28,"strength":16},"guardian":"Nymeia, the Spinner","current_exp":18880,"starting_city":"Gridania","exp_to_next_level":28000,"race":"Miqo'te","resistances":{"fire":28,"water":29,"lightning":30,"wind":30,"earth":25,"ice":15},"physical_level":12,"jobs":{"armorer":{"skill_name":"Armorcraft","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Armorer"},"miner":{"skill_name":"Mining","rank":1,"current_skill_points":431,"skillpoint_to_next_level":570,"name":"Miner"},"lancer":{"skill_name":"Polearm","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Lancer"},"goldsmith":{"skill_name":"Goldsmithing","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Goldsmith"},"botanist":{"skill_name":"Botany","rank":9,"current_skill_points":1800,"skillpoint_to_next_level":4300,"name":"Botanist"},"thaumaturge":{"skill_name":"Thaumaturgy","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Thaumaturge"},"leatherworker":{"skill_name":"Leatherworking","rank":1,"current_skill_points":78,"skillpoint_to_next_level":570,"name":"Leatherworker"},"pugilist":{"skill_name":"Hand-to-Hand","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Pugilist"},"fisher":{"skill_name":"Fishing","rank":3,"current_skill_points":748,"skillpoint_to_next_level":880,"name":"Fisher"},"conjurer":{"skill_name":"Conjury","rank":1,"current_skill_points":272,"skillpoint_to_next_level":570,"name":"Conjurer"},"weaver":{"skill_name":"Clothcraft","rank":6,"current_skill_points":1145,"skillpoint_to_next_level":1800,"name":"Weaver"},"shield":{"skill_name":"Shield","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Shield"},"gladiator":{"skill_name":"Sword","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Gladiator"},"carpenter":{"skill_name":"Woodworking","rank":5,"current_skill_points":305,"skillpoint_to_next_level":1500,"name":"Carpenter"},"alchemist":{"skill_name":"Alchemy","rank":8,"current_skill_points":1753,"skillpoint_to_next_level":3200,"name":"Alchemist"},"marauder":{"skill_name":"Axe","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Marauder"},"blacksmith":{"skill_name":"Smithing","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Blacksmith"},"culinarian":{"skill_name":"Cooking","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Culinarian"},"archer":{"skill_name":"Archery","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Archer"}},"gender":"Female","clan":"Seeker of the Sun"}
LOLHEREDOC

    JSON.parse(@char.to_json).should.equal JSON.parse(json)
  end
end

describe 'Character.search' do
  it 'should raise an argument error' do
    should.raise(ArgumentError) { FFXIVLodestone::Character.search() }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(:irrelevant_key => 'value') }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(:world => 'Figaro') }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(:name => 'Ayeron Lifebloom') }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(12345) }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(:name => 'Ayeron Lifebloom', :world => 'FAKE SERVER NAME') }  
  end

  it 'should be empty' do
    FFXIVLodestone::Character.search(:name => 'ABLOO BLOO UGUU', :world => 'Selbina').should.equal([])
  end

  it 'should list characters' do
    FFXIVLodestone::Character.search(:name => 'Lady', :world => 'Selbina').should.equal(
      [{:world=>"Selbina", :portrait_thumb_url=>"http://static.finalfantasyxiv.com/csnap/v05m_ss_7bd793d507a92d2c415b306a83280d19.png?gediwpzz", :name=>"Lady Simmons", :id=>1015990}, {:world=>"Selbina", :portrait_thumb_url=>"http://static.finalfantasyxiv.com/csnap/14fij_ss_f19cd042628445e22a17a9362cb91f26.png?gee0yejc", :name=>"Shukick Fairlady", :id=>1195603}]
    )
  end
end
