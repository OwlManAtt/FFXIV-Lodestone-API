$:.unshift("#{File.expand_path(File.dirname(__FILE__))}/../lib")
require 'bacon'
require 'ffxiv-lodestone'

# Make the character class open our saved HTML...
class FFXIVLodestone::Character
  def get_html(id)
    open("./characters/#{id}.html")
  end
end

describe 'Character(invalid)' do 
  it 'should raise an exception' do
    should.raise(FFXIVLodestone::Character::NotFoundException) { FFXIVLodestone::Character.new('invalid') }
  end
end

describe 'Character(1015990)' do
  before do
    @char = FFXIVLodestone::Character.new(1015990)
  end

  it 'should have profile data' do
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
    @char.skills.list.map(&:name).sort.should.equal ['Conjurer','Carpenter','Leatherworker','Weaver','Alchemist','Miner','Botanist','Fisher'].sort
  end

  it 'should be convertable to json' do
    json = <<LOLHEREDOC
{"clan":"Seeker of the Sun","resistances":{"ice":15,"fire":28,"water":29,"lightning":30,"wind":30,"earth":25},"first_name":"Lady","nameday":"4th Sun of the 3rd Umbral Moon","current_exp":18880,"last_name":"Simmons","attributes":{"strength":16,"vitality":24,"dexterity":17,"intelligence":36,"mind":37,"piety":28},"guardian":"Nymeia, the Spinner","exp_to_next_level":28000,"starting_city":"Gridania","physical_level":12,"race":"Miqo'te","jobs":{"goldsmith":{"skill_name":"Goldsmithing","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Goldsmith"},"thaumaturge":{"skill_name":"Thaumaturgy","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Thaumaturge"},"botanist":{"skill_name":"Botany","rank":9,"current_skill_points":1800,"skillpoint_to_next_level":4300,"name":"Botanist"},"pugilist":{"skill_name":"Hand-to-Hand","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Pugilist"},"leatherworker":{"skill_name":"Leatherworking","rank":1,"current_skill_points":78,"skillpoint_to_next_level":570,"name":"Leatherworker"},"conjurer":{"skill_name":"Conjury","rank":1,"current_skill_points":272,"skillpoint_to_next_level":570,"name":"Conjurer"},"fisher":{"skill_name":"Fishing","rank":3,"current_skill_points":748,"skillpoint_to_next_level":880,"name":"Fisher"},"gladiator":{"skill_name":"Sword","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Gladiator"},"weaver":{"skill_name":"Clothcraft","rank":6,"current_skill_points":1145,"skillpoint_to_next_level":1800,"name":"Weaver"},"carpenter":{"skill_name":"Woodworking","rank":5,"current_skill_points":305,"skillpoint_to_next_level":1500,"name":"Carpenter"},"marauder":{"skill_name":"Axe","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Marauder"},"alchemist":{"skill_name":"Alchemy","rank":8,"current_skill_points":1753,"skillpoint_to_next_level":3200,"name":"Alchemist"},"shield":{"skill_name":"Shield","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Shield"},"blacksmith":{"skill_name":"Smithing","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Blacksmith"},"archer":{"skill_name":"Archery","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Archer"},"culinarian":{"skill_name":"Cooking","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Culinarian"},"armorer":{"skill_name":"Armorcraft","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Armorer"},"lancer":{"skill_name":"Polearm","rank":0,"current_skill_points":0,"skillpoint_to_next_level":0,"name":"Lancer"},"miner":{"skill_name":"Mining","rank":1,"current_skill_points":431,"skillpoint_to_next_level":570,"name":"Miner"}},"gender":"Female","world":"Selbina"}
LOLHEREDOC

    JSON.parse(@char.to_json).should.equal JSON.parse(json)
  end
end
