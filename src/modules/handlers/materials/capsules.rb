# frozen_string_literal: true

def handle_capsules
  begin
    player_loot = get_player_loot

    loot_capsules =
      player_loot.select { |l| l['lootName'].start_with?('CHEST_') }
    loot_capsules.each do |c|
      recipes = get_recipes_for_item(c['lootId'])
      if recipes[0]['slots'].length > 1 || !recipes[0]['type'] == 'OPEN'
        c['needs_key'] = true
      else
        c['needs_key'] = false
      end
    end
    loot_capsules = loot_capsules.select { |c| c['needs_key'] == false }

    if count_loot_items(loot_capsules) > 0
      puts "Found #{count_loot_items(loot_capsules)} capsules:".light_blue
      loot_capsules.each do |c|
        puts "#{c['count']}x ".light_black +
               "#{get_chest_name(c['lootId'])}".light_white
      end

      if ($ans_y).include? user_input_check(
        "Open #{count_loot_items(loot_capsules)} (keyless) capsules?",
        $ans_yn,
        $ans_yn_d,
        'confirm'
      )
        $s_opened += count_loot_items(loot_capsules)
        threads =
          loot_capsules.map do |c|
            Thread.new do
              res = post_recipe(c['lootId'] + '_OPEN', c['lootId'], c['count'])
              res['added'].each do |r|
                if r['playerLoot']['lootId'] == 'CURRENCY_champion'
                  $s_blue_essence += r['deltaCount']
                end
              end
            end
          end
        threads.each(&:join)
        puts 'Done!'.green
      end
    else
      puts 'Found no keyless capsules to open.'.yellow
    end
  rescue => exception
    handle_exception(exception, 'Capsules')
  end
end
