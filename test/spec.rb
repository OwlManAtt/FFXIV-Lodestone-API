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

describe 'Character.search' do
  it 'should raise an argument error' do
    should.raise(ArgumentError) { FFXIVLodestone::Character.search() }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(:irrelevant_key => 'value') }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(:world => 'Figaro') }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(12345) }  
    should.raise(ArgumentError) { FFXIVLodestone::Character.search(:name => 'Ayeron Lifebloom', :world => 'FAKE SERVER NAME') }  
  end

  it 'should accept server as an integer' do
    should.not.raise(ArgumentError) { FFXIVLodestone::Character.search(:name => 'Ayeron Lifebloom', :world => 7) }
    
    c = FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom', :world => 7)
    c.character_id.should.equal 1502635
  end

  it 'should be empty' do
    FFXIVLodestone::Character.search(:name => 'ABLOO BLOO UGUU', :world => 'Selbina').should.equal([])
  end
  
  it 'should allow no :world' do
    should.not.raise(ArgumentError) { FFXIVLodestone::Character.search(:name => 'Ayeron Lifebloom')}
    FFXIVLodestone::Character.search(:name => 'Ayeron Lifebloom').should.equal([{:portrait_thumb_url=>"http://static.finalfantasyxiv.com/csnap/1drdb_ss_14e13bdee6f804fa6b989297ba747306.png?geepsvty", :world=>"Figaro", :name=>"Ayeron Lifebloom", :id=>1502635}])
  end

  it 'should list characters' do
    FFXIVLodestone::Character.search(:name => 'Lady', :world => 'Selbina').should.equal(
      [{:world=>"Selbina", :portrait_thumb_url=>"http://static.finalfantasyxiv.com/csnap/v05m_ss_7bd793d507a92d2c415b306a83280d19.png?gediwpzz", :name=>"Lady Simmons", :id=>1015990}, {:world=>"Selbina", :portrait_thumb_url=>"http://static.finalfantasyxiv.com/csnap/14fij_ss_f19cd042628445e22a17a9362cb91f26.png?gee0yejc", :name=>"Shukick Fairlady", :id=>1195603}]
    )
  end
end
describe 'Character(invalid)' do 
  it 'is an invalid id' do
    should.raise(FFXIVLodestone::Character::NotFoundException) { FFXIVLodestone::Character.new('invalid') }
  end

  it 'is a bad argument list' do
    should.raise(ArgumentError) { FFXIVLodestone::Character.new(:id => 1, :name => 'Ayeron Lifebloom', :world => 'Figaro') }
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
    should.not.raise(ArgumentError) { FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom') }
  end
end

describe "Character.new(:name => foo, :world => bar)" do
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

    # This character started in LL. The page structure is slightly different than a Gridanian
    # character. Why? So the top box can be red. :psyduck:
    char = FFXIVLodestone::Character.new(:name => 'Ryoko Antihaijin', :world => 'Figaro')
    char.name.should.equal 'Ryoko Antihaijin'
    char.character_id.should.equal 1124548
    char.starting_city.should.equal 'Limsa Lominsa'
    char.jobs.thaumaturge.rank.should.equal 29 # pro-tier

    # For the sake of completeness, here's one that started in Ul'dah.
    char = FFXIVLodestone::Character.new(:id => 2440978)
    char.name.should.equal 'Warukyure Asura'
    char.character_id.should.equal 2440978
    char.world.should.equal 'Trabia'
    char.starting_city.should.equal "Ul'dah"

    # Worldless!
    char = FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom')
    char.name.should.equal 'Ayeron Lifebloom'
    char.character_id.should.equal 1502635
    char.world.should.equal 'Figaro'
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
    @char.portrait_url.should.equal 'http://static.finalfantasyxiv.com/csnap/v05m_m_7bd793d507a92d2c415b306a83280d19.png'
    @char.portrait_thumb_url.should.equal 'http://static.finalfantasyxiv.com/csnap/v05m_ss_7bd793d507a92d2c415b306a83280d19.png'
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

    # make sure the alias is working!
    @char.jobs == @char.skills
  end

  it 'should list all leveled jobs' do
    @char.skills.levelled.map(&:name).sort.should.equal ['Conjurer','Carpenter','Leatherworker','Weaver','Alchemist','Miner','Botanist','Fisher'].sort
  end

  it 'should be convertable to json' do
    json = <<LOLHEREDOC
{"world":"Selbina","clan":"Seeker of the Sun","first_name":"Lady","portrait_url":"http:\/\/static.finalfantasyxiv.com\/csnap\/v05m_m_7bd793d507a92d2c415b306a83280d19.png","character_id":1015990,"current_exp":18880,"last_name":"Simmons","nameday":"4th Sun of the 3rd Umbral Moon","exp_to_next_level":28000,"portrait_thumb_url":"http:\/\/static.finalfantasyxiv.com\/csnap\/v05m_ss_7bd793d507a92d2c415b306a83280d19.png","guardian":"Nymeia, the Spinner","physical_level":12,"jobs":{"alchemist":{"rank":8,"current_skill_points":1753,"skillpoint_to_next_level":3200,"name":"Alchemist","skill_name":"Alchemy"},"marauder":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Marauder","skill_name":"Axe"},"blacksmith":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Blacksmith","skill_name":"Smithing"},"culinarian":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Culinarian","skill_name":"Cooking"},"archer":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Archer","skill_name":"Archery"},"armorer":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Armorer","skill_name":"Armorcraft"},"miner":{"rank":1,"current_skill_points":431,"skillpoint_to_next_level":570,"name":"Miner","skill_name":"Mining"},"lancer":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Lancer","skill_name":"Polearm"},"goldsmith":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Goldsmith","skill_name":"Goldsmithing"},"botanist":{"rank":9,"current_skill_points":1800,"skillpoint_to_next_level":4300,"name":"Botanist","skill_name":"Botany"},"thaumaturge":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Thaumaturge","skill_name":"Thaumaturgy"},"leatherworker":{"rank":1,"current_skill_points":78,"skillpoint_to_next_level":570,"name":"Leatherworker","skill_name":"Leatherworking"},"pugilist":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Pugilist","skill_name":"Hand-to-Hand"},"fisher":{"rank":3,"current_skill_points":748,"skillpoint_to_next_level":880,"name":"Fisher","skill_name":"Fishing"},"conjurer":{"rank":1,"current_skill_points":272,"skillpoint_to_next_level":570,"name":"Conjurer","skill_name":"Conjury"},"weaver":{"rank":6,"current_skill_points":1145,"skillpoint_to_next_level":1800,"name":"Weaver","skill_name":"Clothcraft"},"gladiator":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Gladiator","skill_name":"Sword"},"carpenter":{"rank":5,"current_skill_points":305,"skillpoint_to_next_level":1500,"name":"Carpenter","skill_name":"Woodworking"},"shield":{"rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Shield","skill_name":"Shield"}},"race":"Miqo'te","resistances":{"earth":25,"ice":15,"fire":28,"water":29,"lightning":30,"wind":30},"starting_city":"Gridania","attributes":{"mind":37,"piety":28,"strength":16,"vitality":24,"dexterity":17,"intelligence":36},"gender":"Female"}
LOLHEREDOC

    JSON.parse(@char.to_json).should.equal JSON.parse(json)
  end
end
