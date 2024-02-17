# frozen_string_literal: true

require_relative '../loot_metainfo'
require_relative '../../class/dictionary'

# Redeems mastery 6/7 tokens as efficiently as possible:
# Prefers champion shard over champion permanent over blue essence
# @param client Client connector
def handle_mastery_tokens(client)
  loot_mastery_tokens = grab_upgradable_tokens(client)

  if loot_mastery_tokens.count.zero?
    puts 'Found no upgradable set of Mastery Tokens.'.yellow
    return
  end

  loot_mastery_tokens = loot_mastery_tokens.sort_by { |l| [l['lootName'], l['itemDesc']] }
  puts "We could upgrade the following champions:\n".light_blue

  needed_resources = determine_token_crafting_recources(client, loot_mastery_tokens)
  owned_essence = client.req_get_player_loot.select { |l| l['lootId'] == Dictionary::BLUE_ESSENCE }[0]['count']

  essence_missing = needed_resources['essence'] - owned_essence
  if essence_missing.positive?
    puts "You're missing #{essence_missing} Blue Essence needed to proceed. Skipping...".yellow
    return
  end

  execute_token_crafting(client, loot_mastery_tokens, needed_resources)
  puts 'Done!'.green
rescue StandardError => e
  handle_exception(e, 'token upgrades')
end

# Reduces player loot to a set of tokens that can be upgraded
# @param client Client connector
def grab_upgradable_tokens(client)
  client.req_get_player_loot.select do |l|
    (l['lootName'] == Dictionary::MASTERY_6_TOKEN && l['count'] == 2) ||
      (l['lootName'] == Dictionary::MASTERY_7_TOKEN && l['count'] == 3)
  end
end

# Calculates the cheapest way to upgrade each token set
# @param client Client connector
# @param loot_mastery_tokens Set of upgradable tokens
def determine_token_crafting_recources(client, loot_mastery_tokens)
  player_loot = client.req_get_player_loot
  needed_resources = {
    'shards' => 0,
    'perms' => 0,
    'essence' => 0
  }

  loot_mastery_tokens.each do |t|
    print pad(t['itemDesc'], 15, right: false).light_white
    print ' to Mastery Level '.light_black
    print t['lootName'][-1].light_white
    print ' using '.light_black

    calc_token_crafting_resource(player_loot, t, needed_resources)
    puts
  end
  puts

  needed_resources
end

def check_token_ref_crafting_material(player_loot, ref_id, type)
  type_id = type == 'shard' ? Dictionary::CHAMPION_SHARD : Dictionary::CHAMPION_PERMANENT

  ref_mat = player_loot.select do |l|
    l['type'] == type_id && ref_id == l['storeItemId'].to_s
  end

  !ref_mat.empty? && ref_mat[0]['count'].positive?
end

def calc_token_crafting_resource(player_loot, token, needed_resources)
  if check_token_ref_crafting_material(player_loot, token['refId'], 'shard')
    print 'a champion shard.'.green
    needed_resources['shards'] += 1
    token['upgrade_type'] = 'shard'
  elsif check_token_ref_crafting_material(player_loot, token['refId'], 'perm')
    print 'a champion permanent.'.green
    needed_resources['perms'] += 1
    token['upgrade_type'] = 'permanent'
  else
    recipe_cost = mastery_upgrade_cost(client, (token['lootName'])[-1])
    print "#{recipe_cost} Blue Essence.".yellow
    needed_resources['essence'] += recipe_cost
    token['upgrade_type'] = 'essence'
  end
end

# Grabs token set blue essence upgrade cost
# @param client Client connector
# @param level Token level (6/7)
def mastery_upgrade_cost(client, level)
  recipes = client.req_get_recipes_for_item("#{Dictionary.const_get("MASTERY_#{level}_TOKEN")}-1")

  recipe_cost = recipes.select do |r|
    r['recipeName'] == "CHAMPION_TOKEN_#{level}_redeem_withessence"
  end
  recipe_cost[0]['slots'][1]['quantity']
end

# Builds the confirm question string from resources about to be consumed to upgrade tokens
# @param loot_mastery_tokens Upgradable token sets
# @param needed_resources Hash of needed shards, perms and blue essence
def build_token_crafting_confirm_question(loot_mastery_tokens, needed_resources)
  question_string = "Upgrade #{loot_mastery_tokens.count} champions using "
  question_string += "#{needed_resources['shards']} Shards, " if needed_resources['shards'].positive?
  question_string += "#{needed_resources['perms']} Permanents, " if needed_resources['perms'].positive?
  question_string += "#{needed_resources['essence']} Blue Essence, " if needed_resources['essence'].positive?

  question_string = question_string.delete_suffix(', ')
  "#{question_string}?"
end

# Will redeem tokens after confirmation
# @param client Client connector
# @param loot_mastery_tokens Upgradable token sets
# @param needed_resources Hash of needed shards, perms and blue essence
def execute_token_crafting(client, loot_mastery_tokens, needed_resources)
  unless ans_y.include? user_input_check(
    build_token_crafting_confirm_question(loot_mastery_tokens, needed_resources),
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    return
  end

  loot_mastery_tokens.each do |t|
    target_level = (t['lootName'])[-1]
    case t['upgrade_type']
    when 'shard'
      client.req_post_recipe(
        "CHAMPION_TOKEN_#{target_level}_redeem_withshard",
        [t['lootId'], "CHAMPION_RENTAL_#{t['refId']}"],
        1
      )
    when 'permanent'
      client.req_post_recipe(
        "CHAMPION_TOKEN_#{target_level}_redeem_withpermanent",
        [t['lootId'], "CHAMPION_#{t['refId']}"],
        1
      )
    when 'essence'
      client.req_post_recipe(
        "CHAMPION_TOKEN_#{target_level}_redeem_withessence",
        [t['lootId'], 'CURRENCY_champion'],
        1
      )
    end

    client.stat_tracker.add_redeemed(1)
  end
end
