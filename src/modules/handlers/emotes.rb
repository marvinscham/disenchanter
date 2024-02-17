# frozen_string_literal: true

require_relative 'generic_loot'

# Wrapper for emotes
# @param client Client connector
# @note No shards for emotes
def handle_emotes(client)
  handle_generic(client, 'Emotes', 'EMOTE')

  client.refresh_loot
  # Re-handle icons in case new disenchant candidates came up
  handle_generic(client, 'Emotes', 'EMOTE') if handle_esports_emotes(client)
end

# Rerolls non-disenchantable esports emotes into disenchantable ones
# @return true if re-run is needed
def handle_esports_emotes(client)
  esports_emotes = find_esports_emotes(client)
  if count_loot_items(esports_emotes).zero?
    puts 'Found no Esports Emotes to re-roll.'.yellow
    return false
  end

  puts "Found #{count_loot_items(esports_emotes)} Esports Emotes."

  unless ans_y.include? user_input_check(
    "Re-roll #{count_loot_items(esports_emotes)} already owned Esports Emotes?",
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    return false
  end

  client.stat_tracker.add_crafted(count_loot_items(esports_emotes))
  threads =
    esports_emotes.map do |g|
      Thread.new { client.req_post_recipe('EMOTE_forge', g['lootId'], g['count']) }
    end
  threads.each(&:join)

  puts 'Done!'.green
  client.refresh_loot

  true
end

def find_esports_emotes(client)
  player_loot = client.req_get_player_loot
  player_loot.select do |l|
    l['type'] == 'EMOTE' \
      && l['disenchantLootName'] == '' \
      && l['redeemableStatus'] == 'ALREADY_OWNED'
  end
end
