# frozen_string_literal: true

require_relative '../../class/menu/champions_menu'

require_relative '../loot_metainfo'

require_relative 'champions_collection'
require_relative 'champions_exclusions'
require_relative 'champions_mastery'
require_relative 'champions_owned'
require_relative 'champions_tokens'

# Handles any champion shard and champion permanent related loot actions
# @param client Client connector
def handle_champions(client)
  loot_shards = init_champion_shard_selection(client)

  if count_loot_items(loot_shards).zero?
    puts I18n.t(:'handler.champion.no_shards_found').yellow
    return
  end

  puts I18n.t(:'handler.champion.found_shards', count: count_loot_items(loot_shards)).light_blue
  loot_shards = handle_champions_owned(loot_shards)

  champions_menu = ChampionsMenu.new(client, loot_shards)
  bail = champions_menu.run_loop
  return if bail

  loot_shards = champions_menu.loot_shards

  if count_loot_items(loot_shards).zero?
    puts I18n.t(:'handler.champion.already_done').green
    return
  end

  present_champion_selection(loot_shards)

  pre_exclusion_count = count_loot_items(loot_shards)
  loot_shards = handle_champions_exclusions(loot_shards)

  return if count_loot_items(loot_shards).zero?

  present_champion_selection(loot_shards) if pre_exclusion_count != count_loot_items(loot_shards)

  execute_champions_disenchant(client, loot_shards)
  puts I18n.t(:'common.done').green
rescue StandardError => e
  handle_exception(e, I18n.t(:'loot.champions'))
end

def present_champion_selection(loot_shards)
  puts I18n.t(:'handler.champion.present_selection', count: count_loot_items(loot_shards)).light_blue
  loot_shards.each do |l|
    loot_value = l['disenchantValue'] * l['count']
    print pad("#{l['count']}x ", 5, right: false).light_black
    print pad(l['itemDesc'], 15).light_white
    print ' @ '.light_black
    print pad("#{loot_value} #{I18n.t(:'loot.blue_essence_short')}", 8, right: false).light_black
    print_champion_disenchant_addendum(l)
    puts
  end
end

def print_champion_disenchant_addendum(shard)
  if shard['count_keep'].positive?
    print " #{I18n.t(:'handler.champion.shards_to_keep', count: shard['count_keep'])}".green
  elsif shard['disenchant_note'].length.positive?
    print " #{shard['disenchant_note']}"
  end
end

def init_champion_shard_selection(client)
  player_loot = client.req_get_player_loot
  loot_shards = player_loot.select { |l| l['type'] == Dictionary::CHAMPION_SHARD }

  loot_perms = player_loot.select { |l| l['type'] == Dictionary::CHAMPION_PERMANENT }
  if count_loot_items(loot_perms).positive? && (ans_y.include? user_input_check(
    I18n.t(:'handler.champion.ask_include_permanents'),
    ans_yn,
    ans_yn_d
  ))
    loot_shards.concat(loot_perms)
  end

  loot_shards
end

def execute_champions_disenchant(client, loot_shards)
  total_be_value = 0
  loot_shards.each do |l|
    total_be_value += l['disenchantValue'] * l['count']
  end

  if ans_y.include? user_input_check(
    I18n.t(:'handler.champion.ask_disenchant', count: count_loot_items(loot_shards), amount: total_be_value),
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    client.stat_tracker.add_blue_essence(total_be_value)
    client.stat_tracker.add_disenchanted(count_loot_items(loot_shards))
    threads =
      loot_shards.map do |s|
        Thread.new do
          client.req_post_recipe(
            s['disenchantRecipeName'],
            s['lootId'],
            s['count']
          )
        end
      end
    threads.each(&:join)
  end
end
