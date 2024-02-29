# frozen_string_literal: true

require_relative '../loot_metainfo'
require_relative '../../class/dictionary'

# Handles generic loot types
# @param client Client connector
# @param name Display name ("Skin Shards")
# @param type Riot loot type name ("SKIN_RENTAL")
def handle_generic(client, name, type)
  loot_generic = select_generic_loot(client, type)
  if count_loot_items(loot_generic).zero?
    puts I18n.t(:'handler.generic.found_nothing', name:).yellow
    return
  end

  puts I18n.t(:'handler.generic.found_some', count: count_loot_items(loot_generic), name:).light_blue

  loot_generic = handle_generic_owned(loot_generic, name)
  return if loot_generic == false

  if count_loot_items(loot_generic).zero?
    puts I18n.t(:'handler.generic.found_no_owned', name:).yellow
    return
  end

  loot_name_index = loot_generic[0]['itemDesc'] == '' ? 'localizedName' : 'itemDesc'
  totals = prepare_generic_totals(loot_generic)
  disenchant_info = create_generic_disenchant_info(loot_generic, loot_name_index, name, totals)

  unless ans_y.include? user_input_check(
    I18n.t(:'handler.generic.ask_disenchant',
           count: count_loot_items(loot_generic),
           loot: name,
           currency: disenchant_info),
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    return
  end

  execute_generic_disenchant(client, loot_generic, totals)

  puts I18n.t(:'common.done').green
rescue StandardError => e
  handle_exception(e, name)
end

def select_generic_loot(client, type)
  player_loot = client.req_get_player_loot
  generic_loot = player_loot.select { |l| l['type'] == type }
  # Things like esports icons cannot be disenchanted -> drop
  generic_loot.reject { |l| l['disenchantLootName'] == '' }
end

def handle_generic_owned(loot_generic, name)
  contains_unowned_items = false
  loot_generic.each do |l|
    contains_unowned_items = true if l['redeemableStatus'] != Dictionary::STATUS_OWNED
  end

  return loot_generic unless contains_unowned_items

  case ask_option_keep_unowned(name)
  when 'x'
    puts I18n.t(:'handler.generic.action_cancelled').yellow
    return false
  when 'y'
    loot_generic = loot_generic.select { |g| g['redeemableStatus'] == Dictionary::STATUS_OWNED }
    puts I18n.t(:'handler.generic.filtered_down', count: count_loot_items(loot_generic)).light_blue
  when 'n'
    # Nothing to do
  else
    raise StandardError, 'This shouldn\'t be possible, yet here we are.'
  end

  loot_generic
end

def ask_option_keep_unowned(name)
  user_input_check(
    "#{I18n.t(:'handler.generic.keep_unowned', loot: name)}\n".light_cyan +
      '[y] '.light_white + "#{I18n.t(:'common.yup')}\n".light_cyan + '[n] '.light_white +
      "#{I18n.t(:'common.nah')}\n".light_cyan + '[x] '.light_white +
      "#{I18n.t(:'menu.back_to_main')}\n".light_cyan + "#{I18n.t(:'menu.option')} ".white,
    %w[y n x],
    '[y|n|x]',
    ''
  )
end

def prepare_generic_totals(loot_generic)
  totals = {
    'oe' => 0,
    'be' => 0
  }
  loot_generic.each do |g|
    totals['be'] += g['disenchantValue'] * g['count'] if g['disenchantLootName'] == Dictionary::BLUE_ESSENCE
    totals['oe'] += g['disenchantValue'] * g['count'] if g['disenchantLootName'] == Dictionary::ORANGE_ESSENCE
  end

  totals
end

def create_generic_disenchant_info(loot_generic, loot_name_index, name, totals)
  loot_generic = loot_generic.sort_by do |l|
    [l['redeemableStatus'], l[loot_name_index]]
  end

  puts I18n.t(:'handler.generic.disenchant_preview', count: count_loot_items(loot_generic), loot: name).light_blue
  loot_generic.each do |l|
    create_generic_info_single(l, loot_name_index)
  end

  disenchant_info = ''
  disenchant_info += "#{totals['oe']} #{I18n.t(:'loot.orange_essence')}" if totals['oe'].positive?
  disenchant_info += ' and ' if totals['be'].positive? && totals['oe'].positive?
  disenchant_info += "#{totals['be']} #{I18n.t(:'loot.blue_essence')}" if totals['be'].positive?
  disenchant_info
end

def create_generic_info_single(loot, loot_name_index)
  loot_name = loot[loot_name_index].chomp
  loot_value = loot['disenchantValue'] * loot['count']
  loot_currency = if loot['disenchantLootName'] == Dictionary::BLUE_ESSENCE
                    I18n.t(:'loot.blue_essence_short')
                  else
                    I18n.t(:'loot.orange_essence_short')
                  end

  print pad("#{loot['count']}x ", 5, right: false).light_black
  print pad(loot_name, 40).light_white
  print ' @ '.light_black
  print pad("#{loot_value} #{loot_currency}", 8, right: false).light_black
  print " (#{I18n.t(:'common.not_owned')})".yellow unless loot['redeemableStatus'] == Dictionary::STATUS_OWNED
  puts
end

def execute_generic_disenchant(client, loot_generic, totals)
  client.stat_tracker.add_disenchanted(count_loot_items(loot_generic))
  client.stat_tracker.add_blue_essence(totals['be'])
  client.stat_tracker.add_orange_essence(totals['oe'])
  threads = loot_generic.map do |g|
    Thread.new { client.req_post_recipe(g['disenchantRecipeName'], g['lootId'], g['count']) }
  end
  threads.each(&:join)
end
