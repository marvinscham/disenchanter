# frozen_string_literal: true

def handle_mythic_essence(client, stat_tracker)
  player_loot = client.req_get_player_loot
  mythic_loot_id = 'CURRENCY_mythic'

  loot_essence = player_loot.select { |l| l['lootId'] == mythic_loot_id }
  loot_essence = loot_essence[0]

  if loot_essence.nil? || loot_essence['count'].zero?
    puts 'Found no Mythic Essence to use.'.yellow
    return
  end

  puts "Found #{loot_essence['count']} Mythic Essence.".light_blue
  craft_mythic_type_names = [
    'Blue Essence',
    'Orange Essence',
    'Random Skin Shards'
  ]

  craft_mythic_type =
    user_input_check(
      "Okay, what would you like to craft?\n" +
        "[1] #{craft_mythic_type_names[0]}\n" +
        "[2] #{craft_mythic_type_names[1]}\n" +
        "[3] #{craft_mythic_type_names[2]}\n" + "[x] Cancel\n",
      %w[1 2 3 x],
      '[1|2|3|x]'
    )

  case craft_mythic_type
  # Blue Essence, Orange Essence, Random Skin Shard
  when '1'
    recipe_target = 'CURRENCY_champion'
  when '2'
    recipe_target = 'CURRENCY_cosmetic'
  when '3'
    recipe_target = 'CHEST_291'
  when 'x'
    puts 'Mythic crafting canceled.'.yellow
    return
  end

  recipes = client.req_get_recipes_for_item(mythic_loot_id)
  recipes =
    recipes.select { |r| r['outputs'][0]['lootName'] == recipe_target }

  if recipes.empty?
    puts "Recipes for #{craft_mythic_type_names[craft_mythic_type.to_i - 1]} seem to be unavailable.".yellow
    return
  end
  recipe = recipes[0]

  puts "Recipe found: #{recipe['contextMenuText']} for " \
       "#{recipe['slots'][0]['quantity']} Mythic Essence".light_blue

  craft_mythic_amount =
    user_input_check(
      'Alright, how much Mythic Essence should we use to craft ' \
      "#{craft_mythic_type_names[craft_mythic_type.to_i - 1]}?",
      (1..loot_essence['count'].to_i)
        .to_a
        .append('all')
        .map!(&:to_s),
      "[1..#{loot_essence['count']}|all|x]"
    )

  if craft_mythic_amount == 'x'
    puts 'Mythic crafting canceled.'.yellow
    return
  end
  craft_mythic_amount = loot_essence['count'] if craft_mythic_amount == 'all'
  craft_mythic_amount = craft_mythic_amount.to_i

  could_craft =
    (craft_mythic_amount / recipe['slots'][0]['quantity']).floor

  if could_craft.zero?
    puts 'Not enough Mythic Essence for that recipe.'.yellow
    return
  end

  craft_quantity = could_craft * recipe['outputs'][0]['quantity']
  craft_target_name = craft_mythic_type_names[craft_mythic_type.to_i - 1]
  craft_price = could_craft * recipe['slots'][0]['quantity']

  if ans_y.include? user_input_check(
    "Craft #{craft_quantity} #{craft_target_name} from #{craft_price} Mythic Essence?",
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    case craft_mythic_type
    when '1'
      stat_tracker.add_blue_essence(craft_quantity)
    when '2'
      stat_tracker.add_orange_essence(craft_quantity)
    end
    stat_tracker.add_crafted(could_craft)

    post_recipe(
      recipe['recipeName'],
      mythic_loot_id,
      (craft_mythic_amount / recipe['slots'][0]['quantity']).floor
    )
    puts 'Done!'.green
  end
rescue => e
  handle_exception(e, 'Mythic Essence')
end
