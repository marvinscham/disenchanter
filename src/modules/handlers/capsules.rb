# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative '../loot_metainfo'

# Opens keyless chests/capsules
# @param client Client connector
# @param accept Auto-accept all steps
def handle_capsules(client, accept = 0)
  player_loot = client.req_get_player_loot

  loot_capsules = filter_key_capsules(client, player_loot)

  if count_loot_items(loot_capsules).zero?
    puts I18n.t(:'handler.capsule.no_capsules_found').yellow
    return
  end

  print_capsule_summary(client, loot_capsules)

  if accept >= 1 || ans_y.include?(user_input_check(
    I18n.t(:'handler.capsule.ask_open_capsules', count: count_loot_items(loot_capsules)),
    ans_yn, ans_yn_d, 'confirm'
  ))
    process_keyless_capsule_requests(loot_capsules, client)
    puts I18n.t(:'common.done').green
  end
rescue StandardError => e
  handle_exception(e, 'capsules')
end

def filter_key_capsules(client, player_loot)
  loot_capsules = player_loot.select { |l| l['lootName'].start_with?('CHEST_') }

  loot_capsules.each do |c|
    recipes = client.req_get_recipes_for_item(c['lootId'])
    c['needs_key'] = recipes[0]['slots'].length > 1 || !recipes[0]['type'] == 'OPEN'
  end

  loot_capsules.reject { |c| c['needs_key'] }
rescue StandardError => e
  handle_exception(e, 'capsules: filtering')
end

def process_keyless_capsule_requests(loot_capsules, client)
  threads =
    loot_capsules.map do |c|
      Thread.new do
        res = client.req_post_recipe("#{c['lootId']}_OPEN", c['lootId'], c['count'])
        unless res.nil?
          res['added'].each do |r|
            if r['playerLoot']['lootId'] == Dictionary::BLUE_ESSENCE
              client.stat_tracker.add_blue_essence(r['deltaCount'])
            end

            if r['playerLoot']['lootId'] == Dictionary::ORANGE_ESSENCE
              client.stat_tracker.add_orange_essence(r['deltaCount'])
            end
          end
        end
      end
    end
  threads.each(&:join)

  client.stat_tracker.add_opened(count_loot_items(loot_capsules))
rescue StandardError => e
  handle_exception(e, 'capsules: request')
end

def print_capsule_summary(client, loot_capsules)
  puts I18n.t(:'handler.capsule.found_capsules', count: count_loot_items(loot_capsules)).light_blue
  loot_capsules.each do |c|
    puts "#{c['count']}x ".light_black + get_chest_name(client, c['lootId']).light_white
  end
rescue StandardError => e
  handle_exception(e, 'capsules: summary')
end
