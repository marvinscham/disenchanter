# frozen_string_literal: true

# Will keep one shard for each champion
def handle_champions_collection(loot_shards)
  loot_shards.each do |l|
    l['count'] -= 1
    l['count_keep'] += 1
  end

  loot_shards
rescue StandardError => e
  handle_exception(e, I18n.t(:'handler.exception.step.champions.collection'))
end
