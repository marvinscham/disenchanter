# frozen_string_literal: true

def handle_key_fragments
  begin
    player_loot = get_player_loot

    loot_keys =
      player_loot.select { |l| l['lootId'] == 'MATERIAL_key_fragment' }
    if count_loot_items(loot_keys) >= 3
      puts "Found #{count_loot_items(loot_keys)} key fragments.".light_blue
      if ($ans_y).include? user_input_check(
        "Craft #{(count_loot_items(loot_keys) / 3).floor} keys from #{count_loot_items(loot_keys)} key fragments?",
        $ans_yn,
        $ans_yn_d,
        'confirm'
      )
        $s_crafted += (count_loot_items(loot_keys) / 3).floor
        post_recipe(
          'MATERIAL_key_fragment_forge',
          'MATERIAL_key_fragment',
          (count_loot_items(loot_keys) / 3).floor
        )
        puts 'Done!'.green
      end
    else
      puts 'Found less than 3 key fragments.'.yellow
    end
  rescue => exception
    handle_exception(exception, 'Key Fragments')
  end
end
