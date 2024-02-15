# frozen_string_literal: true

# Will keep shards to max out champions above a user-specified mastery level
# @param client Client connector
# @param loot_shards Loot array, pre-filtered to only champion shards and permanents
# @param keep_all Whether to keep all shards that could possibly be used for non-collection purposes
def handle_champions_mastery(client, loot_shards, keep_all: false)
  summoner = client.req_get_current_summoner
  player_mastery = client.req_get_champion_mastery(summoner['summonerId'])
  threshold_champion_ids = []
  mastery6_champion_ids = []
  mastery7_champion_ids = []
  level_threshold = 0

  unless keep_all
    level_threshold = user_input_check(
      'Which mastery level should champions at least be for their shards to be kept?',
      %w[1 2 3 4 5 6],
      '[1..6]'
    ).to_i
  end

  player_mastery.each do |m|
    case m['championLevel']
    when 7
      mastery7_champion_ids << m['championId']
    when 6
      mastery6_champion_ids << m['championId']
    when level_threshold..5
      threshold_champion_ids << m['championId']
    end
  end

  loot_shards.each do |l|
    if mastery7_champion_ids.include? l['storeItemId']
      l['disenchant_note'] = 'at mastery 7'.light_black
    elsif mastery6_champion_ids.include? l['storeItemId']
      l['count'] -= 1
      l['count_keep'] += 1
    elsif keep_all || (threshold_champion_ids.include? l['storeItemId'])
      l['count'] -= 2
      l['count_keep'] += 2
    else
      l['disenchant_note'] = 'below threshold'.yellow
    end
  end

  loot_shards
rescue StandardError => e
  handle_exception(e, 'Champion Shards by Mastery')
end
