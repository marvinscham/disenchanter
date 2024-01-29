# frozen_string_literal: true

def handle_key_fragments(client, stat_tracker)
  player_loot = client.req_get_player_loot

  loot_keys =
    player_loot.select { |l| l['lootId'] == 'MATERIAL_key_fragment' }
  fragment_count = count_loot_items(loot_keys)
  key_count = (count_loot_items(loot_keys) / 3).floor

  if fragment_count < 3
    puts 'Not enough key fragments to craft anything.'.yellow
    return
  end

  puts "Found #{fragment_count} key fragments.".light_blue
  if ans_y.include? user_input_check(
    "Craft #{key_count} keys from #{fragment_count} key fragments?",
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    stat_tracker.add_crafted(key_count)
    client.req_post_recipe(
      'MATERIAL_key_fragment_forge',
      'MATERIAL_key_fragment',
      key_count
    )
    puts 'Done!'.green
  end
rescue StandardError => e
  handle_exception(e, 'Key Fragments')
end
