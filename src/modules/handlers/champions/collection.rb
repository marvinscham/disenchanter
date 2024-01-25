# frozen_string_literal: true

def handle_champions_collection(loot_shards)
  loot_shards.each do |l|
    l['count'] -= 1
    l['count_keep'] += 1
  end

  loot_shards
rescue => e
  handle_exception(e, 'Champion Shards for Collection')
end
