# frozen_string_literal: true

# Keeps a shard for each champion not owned yet
# @param loot_shards Loot array, pre-filtered to only champion shards and permanents
def handle_champions_owned(loot_shards)
  loot_shards.each do |l|
    unless l['redeemableStatus'] == 'ALREADY_OWNED'
      l['count'] -= 1
      l['count_keep'] += 1
    end
  end

  loot_shards
rescue StandardError => e
  handle_exception(e, 'Owned Champion Shards')
end
