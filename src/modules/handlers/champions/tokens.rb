# frozen_string_literal: true

def handle_champions_tokens(player_loot, loot_shards)
  token6_champion_ids = []
  token7_champion_ids = []

  loot_mastery_tokens =
    player_loot.select { |l| l['type'] == 'CHAMPION_TOKEN' }

  loot_mastery_tokens.each do |token|
    if token['lootName'] = 'CHAMPION_TOKEN_6'
      token6_champion_ids << token['refId'].to_i
    elsif token['lootName'] = 'CHAMPION_TOKEN_7'
      token7_champion_ids << token['refId'].to_i
    end
  end

  puts "Found #{token6_champion_ids.length + token7_champion_ids.length} champions with owned mastery tokens".light_black

  loot_shards.each do |l|
    if token6_champion_ids.include? l['storeItemId']
      l['count'] -= 2
      l['count_keep'] += 2
    elsif token7_champion_ids.include? l['storeItemId']
      l['count'] -= 1
      l['count_keep'] += 1
    end
  end
rescue StandardError => e
  handle_exception(e, 'Champion Shards by Tokens')
end
