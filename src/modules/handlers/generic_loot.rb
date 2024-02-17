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
    puts "Found no #{name} to disenchant.".yellow
    return
  end

  puts "Found #{count_loot_items(loot_generic)} #{name}.".light_blue

  loot_generic = handle_generic_owned(loot_generic, name)
  return if loot_generic == false

  if count_loot_items(loot_generic).zero?
    puts "Found no owned #{name} to disenchant.".yellow
    return
  end

  loot_name_index = loot_generic[0]['itemDesc'] == '' ? 'localizedName' : 'itemDesc'
  totals = prepare_generic_totals(loot_generic)
  disenchant_info = create_generic_disenchant_info(loot_generic, loot_name_index, name, totals)

  unless ans_y.include? user_input_check(
    "Disenchant #{count_loot_items(loot_generic)} #{name} for #{disenchant_info}?",
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    return
  end

  execute_generic_disenchant(client, loot_generic, totals)

  puts 'Done!'.green
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
    contains_unowned_items = true if l['redeemableStatus'] != 'ALREADY_OWNED'
  end

  if contains_unowned_items
    user_option =
      user_input_check(
        "Keep #{name} you don't own yet?\n".light_cyan +
          '[y] '.light_white + "Yes\n".light_cyan + '[n] '.light_white +
          "No\n".light_cyan + '[x] '.light_white +
          "Exit to main menu\n".light_cyan + 'Option: '.white,
        %w[y n x],
        '[y|n|x]',
        ''
      )

    case user_option
    when 'x'
      puts 'Action cancelled'.yellow
      return false
    when 'y'
      loot_generic = loot_generic.select { |g| g['redeemableStatus'] == 'ALREADY_OWNED' }
      puts "Filtered to #{count_loot_items(loot_generic)} items.".light_blue
    when 'n'
      # Nothing to do
    else
      raise StandardError, "This shouldn't be possible yet here we are."
    end
  end

  loot_generic
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

  puts "We'd disenchant #{count_loot_items(loot_generic)} #{name} using the option you chose:".light_blue
  loot_generic.each do |l|
    create_generic_info_single(l, loot_name_index)
  end

  disenchant_info = ''
  disenchant_info += "#{totals['oe']} Orange Essence" if totals['oe'].positive?
  disenchant_info += ' and ' if totals['be'].positive? && totals['oe'].positive?
  disenchant_info += "#{totals['be']} Blue Essence" if totals['be'].positive?
  disenchant_info
end

def create_generic_info_single(loot, loot_name_index)
  loot_value = loot['disenchantValue'] * loot['count']
  loot_currency = loot['disenchantLootName'] == Dictionary::BLUE_ESSENCE ? 'BE' : 'OE'

  print pad("#{loot['count']}x ", 5, right: false).light_black
  print pad(loot[loot_name_index], 30).light_white
  print ' @ '.light_black
  print pad("#{loot_value} #{loot_currency}", 8, right: false).light_black
  print ' (not owned)'.yellow if loot['redeemableStatus'] != 'ALREADY_OWNED'
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
