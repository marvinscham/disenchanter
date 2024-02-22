# frozen_string_literal: true

require_relative '../../class/dictionary'

# Keeps only shards to max out champions with owned mastery 6/7 tokens
# @param client Client connector
# @param loot_shards Loot array pre-filtered to only champion shards and permanents
def handle_champions_tokens(client, loot_shards)
  token6_champion_ids = []
  token7_champion_ids = []
  player_loot = client.req_get_player_loot

  loot_mastery_tokens =
    player_loot.select { |l| l['type'] == Dictionary::MASTERY_TOKEN }

  loot_mastery_tokens.each do |token|
    if token['lootName'] == Dictionary::MASTERY_6_TOKEN
      token6_champion_ids << token['refId'].to_i
    elsif token['lootName'] == Dictionary::MASTERY_7_TOKEN
      token7_champion_ids << token['refId'].to_i
    end
  end

  token_champion_count = token6_champion_ids.length + token7_champion_ids.length
  puts I18n.t(:'handler.champion.found_champs_with_tokens', count: token_champion_count).light_black

  adjust_token_counts(loot_shards, token6_champion_ids, token7_champion_ids)
rescue StandardError => e
  handle_exception(e, I18n.t(:'handler.exception.step.champions.tokens'))
end

def adjust_token_counts(loot_shards, token6_champion_ids, token7_champion_ids)
  loot_shards.each do |l|
    if token6_champion_ids.include? l['storeItemId']
      l['count'] -= 2
      l['count_keep'] += 2
    elsif token7_champion_ids.include? l['storeItemId']
      l['count'] -= 1
      l['count_keep'] += 1
    end
  end
end
