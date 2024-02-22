# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for emotes
# @param client Client connector
# @note No shards for emotes
def handle_emotes(client)
  handle_generic(client, I18n.t(:'loot.emotes'), Dictionary::EMOTE)

  client.refresh_loot
  # Re-handle icons in case new disenchant candidates came up
  handle_generic(client, I18n.t(:'loot.emotes'), Dictionary::EMOTE) if handle_esports_emotes(client)
end

# Rerolls non-disenchantable esports emotes into disenchantable ones
# @return true if re-run is needed
def handle_esports_emotes(client)
  esports_emotes = find_esports_emotes(client)
  if count_loot_items(esports_emotes).zero?
    puts I18n.t(:'handler.esports_emotes.none_found').yellow
    return false
  end

  puts I18n.t(:'handler.esports_emotes.found_some', count: count_loot_items(esports_emotes))

  unless ans_y.include? user_input_check(
    I18n.t(:'handler.esports_emotes.ask_re_roll'),
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    return false
  end

  client.stat_tracker.add_crafted(count_loot_items(esports_emotes))
  threads =
    esports_emotes.map do |g|
      Thread.new { client.req_post_recipe(Dictionary::EMOTE_RE_ROLL_RECIPE, g['lootId'], g['count']) }
    end
  threads.each(&:join)

  puts I18n.t(:'common.done').green
  client.refresh_loot

  true
end

def find_esports_emotes(client)
  player_loot = client.req_get_player_loot
  player_loot.select do |l|
    l['type'] == Dictionary::EMOTE \
      && l['disenchantLootName'] == '' \
      && l['redeemableStatus'] == Dictionary::STATUS_OWNED
  end
end
