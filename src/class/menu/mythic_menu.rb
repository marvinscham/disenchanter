# frozen_string_literal: true

require_relative 'menu'

require_relative '../dictionary'

# Menu to handle what to do with mythic essence
class MythicMenu < Menu
  attr_reader :thing_todo, :recipe

  def initialize(client)
    menu_text = I18n.t(:'menu.what_to_do')
    things_todo = {
      '1' => I18n.t(:'mythic_menu.options.blue_essence'),
      '2' => I18n.t(:'mythic_menu.options.orange_essence'),
      '3' => I18n.t(:'mythic_menu.options.random_skin_shards'),
      'x' => I18n.t(:'menu.back_to_main')
    }
    answer_display = I18n.t(:'menu.option')

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
      puts I18n.t(:'mythic_menu.recipes_unavailable', loot: @things_todo[@thing_todo]).yellow
      return
    end
    @recipe = recipes[0]

    puts I18n.t(:'mythic_menu.recipe_found',
                thing_to_craft: @recipe['contextMenuText'],
                amount: @recipe['slots'][0]['quantity']).light_blue

    true
  end
end
