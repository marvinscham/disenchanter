# frozen_string_literal: true

def handle_champions_owned(loot_shards)
  begin
    loot_shards.each do |l|
      unless l['redeemableStatus'] == 'ALREADY_OWNED'
        l['count'] -= 1
        l['count_keep'] += 1
      end
    end
    return loot_shards.select { |l| l['count'] > 0 }
  rescue => exception
    handle_capsules(exception, 'Owned Champion Shards')
  end
end
