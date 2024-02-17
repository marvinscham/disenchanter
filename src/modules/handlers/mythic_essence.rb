# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative '../../class/menu/mythic_menu'

# Handles mythic essence crafting
# @param client Client connector
def handle_mythic_essence(client)
  loot_essence = client.req_get_player_loot.select { |l| l['lootId'] == Dictionary::MYTHIC_ESSENCE }[0]

  if loot_essence.nil? || loot_essence['count'].zero?
    puts 'Found no Mythic Essence to use.'.yellow
    return
  end

  puts "Found #{loot_essence['count']} Mythic Essence.".light_blue

  # Determines what to craft
  mythic_menu = MythicMenu.new(client)
  bail = mythic_menu.run_loop
  return if bail

  craft_target_name = mythic_menu.things_todo[mythic_menu.thing_todo]
  craft_amount = determine_mythic_craft_amount(craft_target_name, mythic_menu.recipe, loot_essence['count'])

  if craft_amount.zero?
    puts 'Not enough Mythic Essence for that.'.yellow
    return
  end

  execute_mythic_crafting(client, craft_target_name, mythic_menu.recipe, craft_amount)
  puts 'Done!'.green
rescue StandardError => e
  handle_exception(e, 'Mythic Essence')
end

# Calculates how the amount of things that can be crafted with user-specified mythic essence
# @param target_name What the thing is called (e.g. Blue Essence, Random Skin Shards, ...)
# @param recipe Recipe to determine cost per unit
# @param essence_owned Owned mythic essence (upper limit for user selection)
def determine_mythic_craft_amount(target_name, recipe, essence_owned)
  craft_mythic_amount = user_input_check(
    'Alright, how much Mythic Essence should we use to craft ' \
    "#{target_name}?",
    (1..essence_owned.to_i)
      .to_a
      .append('all')
      .append('x')
      .map!(&:to_s),
    "[1..#{essence_owned}|all|x]"
  )

  if craft_mythic_amount == 'x'
    puts 'Mythic crafting canceled.'.yellow
    return
  end
  craft_mythic_amount = essence_owned if craft_mythic_amount == 'all'
  craft_mythic_amount = craft_mythic_amount.to_i

  (craft_mythic_amount / recipe['slots'][0]['quantity']).floor
end

# Confirms and executes crafting
# @param client Client connector
# @param target_name Thing to craft
# @param recipe Recipe to craft with
# @param craft_amount How many things to craft
def execute_mythic_crafting(client, target_name, recipe, craft_amount)
  craft_quantity = craft_amount * recipe['outputs'][0]['quantity']
  craft_price = craft_amount * recipe['slots'][0]['quantity']

  unless ans_y.include? user_input_check(
    "Craft #{craft_quantity} #{target_name} from #{craft_price} Mythic Essence?",
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    return
  end

  case recipe['outputs'][0]['lootName']
  when Dictionary::BLUE_ESSENCE
    client.stat_tracker.add_blue_essence(craft_quantity)
  when Dictionary::ORANGE_ESSENCE
    client.stat_tracker.add_orange_essence(craft_quantity)
  end
  client.stat_tracker.add_crafted(craft_amount)

  client.req_post_recipe(
    recipe['recipeName'],
    Dictionary::MYTHIC_ESSENCE,
    craft_amount
  )
end
