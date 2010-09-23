lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'ffxiv-lodestone.rb'
 
Gem::Specification.new do |s|
  s.name        = "ffxiv-lodestone"
  s.version     = FFXIVLodestone::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["owlmanatt"]
  s.email       = ["owlmanatt@gmail.com"]
  s.homepage    = "http://github.com/OwlManAtt/FFXIV-Lodestone-API"
  s.summary     = "Screenscraper for FFXIV character data."
  s.description = "A nice Ruby library for accessing character data on the FFXIV community site. It's a screen scraper, but you can PRETEND you're using something nice."
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.files        = Dir.glob("{lib}/**/*") + %w(README)
  s.require_path = 'lib'
end
