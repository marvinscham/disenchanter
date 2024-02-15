# frozen_string_literal: true

def handle_champions_owned(loot_shards)
  loot_shards.each do |l|
    unless l['redeemableStatus'] == 'ALREADY_OWNED'
      l['count'] -= 1
      l['count_keep'] += 1
    end
  end
  loot_shards.select { |l| l['count'].positive? }
rescue StandardError => e
  handle_exception(e, 'Owned Champion Shards')
end
