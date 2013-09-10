# FFXIV Lodestone API

> This is a screen scraper for the FFXIV community side, Lodestone. It gets information about characters. The Lodestone pages are a huge pile of shit, so this will save you a few hours of hating your life while you write a screen scraper.

The aim is to not break if SquareEnix adds new pieces of data to the page. Any new attributes,
skills, of general pieces of profile data should automatically be handled by this library.

She ain't pretty, but it's decently robust. 

### Installation
It's easy:

```shell
$ gem install ffxiv-lodestone
```

You will need to install the json (pure or extension) gem too. This isn't a dependency because I
don't know of a way to specify an either-or (json-pure or json the native extension) dependency.

### Usage
Take, for example, [this character](http://lodestone.finalfantasyxiv.com/rc/character/status?cicuid=1502635).

In its most simplistic instantiation, `Character.new` with the cicuid from that URL:

```ruby
require 'rubygems'
require 'ffxiv-lodestone'
char = FFXIVLodestone::Character.new(1502635)
```

However, you can also search by name and world. If you're doing name/world, you MUST specify both
of these options of you will get an exception.

```ruby
char = FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom', :world => 'Figaro')
```

**THERE ARE A NUMBER OF CAVEATS INVOLVED IN LOADING-BY-NAME**

1. This involves two HTTP GETs - one for the search page, and one for the profile page. If you are integrating this in to forums or something, you ought to store the character_id number after your first search and use that for subsequent requests.

1. Lodestone's character search is slow to index new characters. It took about a day for my character to show up.

1. Character search has no way of specifying that you want to search for an exact name. If you look up a character with a simple name, like 'Ab Lo', you get multiple search results. In the event that the search has more than one result, an AmbiguousNameError will be raised. You may wish to use the search method and allow your user to pick the correct character, then load it by ID, as demonstrated by this psuedo-code:

```ruby
chars = FFXIVLodestone::Character.search(:name => 'Lady G', :world => 'Figaro')

if chars.length ==  1
  char_id = chars.first[:id]
else
  # display both on a screen for the user to pick, then load the right character by ID
  char_id = . . .
end

character = FFXIVLodestone::Character.new(char_id)
```

**Caveat:** This will only display the first page of search results (so maximum 40). If the character name you are searching for is _that_ ambiguous, then just fucking delete it and reroll with a sane name.

### Ghetto API Doc
The static search method will return a list of hashes. You can use this to avoid ambiguious name errors. Each hash in the array will have id, name, world, and portrait_thumb_url.

```ruby
  results = Character.search(:name => 'Lady G', :world => 'Figaro') # :world is optional, by the way.
```

You can `results.to_json` or `results.to_yaml` this without any problems.

Stuff you can do with a loaded character:

#### `char.to_json`
String containing a JSON representation of the character / jobs.

---

#### `char.to_yaml`
YAML representation of the character (EXPERIMENTAL).

---

#### properties
* `char.name`
* `char.world`
* `char.nameday`
* `char.guardian`
* `char.starting_city`
* `char.physical_level`
* `char.current_exp` 
* `char.exp_to_next_level`
* `char.gender`
* `char.race`
* `char.clan`
* `char.character_id`
* `char.portrait_url`
* `char.portrait_thumb_url`

---

#### `char.jobs`
##### `.levelled`
Array of all skills that have been leveled (ie rank 0 jobs omitted)
##### `.pugilist` (or any class name)
The skill, regardless of if its been leveled or not (ie you can explicitly ask for a skill to see if it's been leveled or not)

---

#### `char.resistances`
StatList (same deal as stats but with fire instead of strength, see method list below)

---

#### `char.stats`
StatList with these methods:
##### `.strength` (or any stat name)
Integer value of the state

A skill object has these methods: 
* `name` 
* `skill_name`
* `rank`
* `skillpoint_to_next_level`
* `current_skill_points` 

---

### FAQ
**Q.** Hey, why doesn't this have HP / MP / TP? They're on the character profile page!

**A.** Because those values change based on the currently equipped job. I don't think they're useful pieces of data. If you have a use case for them, please let me know and I will include them.

**Q.** I see you have a hard-coded list of server to ID mappings. That's awful! What am I supposed to do when new servers open up?

**A.** Yes, it is quite horrible! Hard-coding the list is less bad than doing another HTTP GET when you use Character.search(), though.

But I've anticipated your problem. If new worlds open, you can just pass :world as the ID from the search page's dropdown until I update the gem:

```ruby
FFXIVLodestone::Character.search(:name => 'Ayeron Lifebloom', :world => 7)
FFXIVLodestone::Character.new(:name => 'Ayeron Lifebloom', :world => 7) 
```

### Contributing
If you want to fool around with the source code, you can see if you've fucked everything up:

```shell
$ gem install bacon
$ cd test/
$ bacon spec.rb
```

### TODO
* Figure out what the fuck the stats in parenthesis mean and do something with them.
  * Currently, these are dropped on the floor because I don't know what they mean. The current
    theories include 'Base (with gear)' and 'Stat (with buffs)'.
* Perhaps be able to page through #search() results instead of only having the first 40 available.
