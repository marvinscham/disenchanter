# frozen_string_literal: true

require_relative 'menu'

require_relative '../dictionary'

# Menu to handle what to do with mythic essence
class MythicMenu < Menu
  attr_reader :thing_todo, :recipe

  def initialize(client)
    menu_text = 'Okay, what would you like to craft?'
    things_todo = {
      '1' => 'Blue Essence',
      '2' => 'Orange Essence',
      '3' => 'Random Skin Shards',
      'x' => 'Back to main menu'
    }
    answer_display = 'Option'

    super(client, menu_text, answer_display, things_todo)
    @thing_todo = ''
    @recipe = ''
  end

  def handle_option(thing_todo)
    @thing_todo = thing_todo

    case thing_todo
    when '1'
      thing_to_craft = Dictionary::BLUE_ESSENCE
    when '2'
      thing_to_craft = Dictionary::ORANGE_ESSENCE
    when '3'
      thing_to_craft = Dictionary::RANDOM_SKIN_SHARD
    when 'x'
      return true
    else
      return false
    end

    recipes = @client.req_get_recipes_for_item(Dictionary::MYTHIC_ESSENCE)
    recipes = recipes.select { |r| r['outputs'][0]['lootName'] == thing_to_craft }

    if recipes.empty?
      puts "Recipes for #{@things_todo[@thing_todo]} seem to be unavailable.".yellow
      return
    end
    @recipe = recipes[0]

    puts "Recipe found: #{@recipe['contextMenuText']} for " \
         "#{@recipe['slots'][0]['quantity']} Mythic Essence".light_blue

    true
  end
end
