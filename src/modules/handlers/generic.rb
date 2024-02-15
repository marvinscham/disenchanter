# frozen_string_literal: true

# Handles generic loot types
# @param client Client connector
# @param name Display name ("Skin Shards")
# @param type Riot loot type name ("SKIN_RENTAL")
# @param recipe Riot recipe name ("SKIN_RENTAL_disenchant")
def handle_generic(client, name, type, recipe)
  player_loot = client.req_get_player_loot
  disenchant_all = true

  loot_generic = player_loot.select { |l| l['type'] == type }
  if count_loot_items(loot_generic).zero?
    puts "Found no #{name} to disenchant.".yellow
    return
  end

  puts "Found #{count_loot_items(loot_generic)} #{name}.".light_blue

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
      return
    when 'y'
      disenchant_all = false
      loot_generic =
        loot_generic.select { |g| g['redeemableStatus'] == 'ALREADY_OWNED' }
      puts "Filtered to #{count_loot_items(loot_generic)} items.".light_blue
    end
  end

  if count_loot_items(loot_generic).zero?
    puts "Found no owned #{name} to disenchant.".yellow
    return
  end

  total_oe_value = 0
  loot_generic.each do |g|
    total_oe_value += g['disenchantValue'] * g['count']
  end

  loot_name_index = 'itemDesc'
  loot_name_index = 'localizedName' if loot_generic[0]['itemDesc'] == ''

  loot_generic =
    loot_generic.sort_by do |l|
      [l['redeemableStatus'], l[loot_name_index]]
    end

  puts "We'd disenchant #{count_loot_items(loot_generic)} #{name} using the option you chose:".light_blue
  loot_generic.each do |l|
    loot_value = l['disenchantValue'] * l['count']
    print pad("#{l['count']}x ", 5, right: false).light_black
    print pad(l[loot_name_index], 30).light_white
    print ' @ '.light_black
    print pad("#{loot_value} OE", 8, right: false).light_black
    print ' (not owned)'.yellow if disenchant_all && l['redeemableStatus'] != 'ALREADY_OWNED'
    puts
  end

  if ans_y.include? user_input_check(
    "Disenchant #{count_loot_items(loot_generic)} #{name} for #{total_oe_value} Orange Essence?",
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    client.stat_tracker.add_disenchanted(count_loot_items(loot_generic))
    client.stat_tracker.add_orange_essence(total_oe_value)
    threads =
      loot_generic.map do |g|
        Thread.new { client.req_post_recipe(recipe, g['lootId'], g['count']) }
      end
    threads.each(&:join)

    puts 'Done!'.green
  end
rescue StandardError => e
  handle_exception(e, name)
end
