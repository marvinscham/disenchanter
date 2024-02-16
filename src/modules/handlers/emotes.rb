# frozen_string_literal: true

# Wrapper for emotes, also handles non-disenchantable esports emotes
# @param client Client connector
# @note No shards for emotes
def handle_emotes(client)
  handle_generic(client, 'Emotes', 'EMOTE')
  client.refresh_loot

  player_loot = client.req_get_player_loot
  esports_emotes = player_loot.select do |l|
    l['type'] == 'EMOTE' \
      && l['disenchantLootName'] == '' \
      && l['redeemableStatus'] == 'ALREADY_OWNED'
  end
  if count_loot_items(esports_emotes).zero?
    puts 'Found no Esports Emotes to re-roll.'.yellow
    return
  end

  puts "Found #{count_loot_items(esports_emotes)} Esports Emotes."
  if ans_y.include? user_input_check(
    "Re-roll #{count_loot_items(esports_emotes)} already owned Esports Emotes?",
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    client.stat_tracker.add_crafted(count_loot_items(esports_emotes))
    threads =
      esports_emotes.map do |g|
        Thread.new { client.req_post_recipe('EMOTE_forge', g['lootId'], g['count']) }
      end
    threads.each(&:join)

    puts 'Done!'.green
    client.refresh_loot
  else
    return
  end

  # Re-handle icons in case new disenchant candidates came up
  handle_generic(client, 'Emotes', 'EMOTE')
end
