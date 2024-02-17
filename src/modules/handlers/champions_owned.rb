# frozen_string_literal: true

# Keeps a shard for each champion not owned yet
# @param loot_shards Loot array, pre-filtered to only champion shards and permanents
def handle_champions_owned(loot_shards)
  loot_shards.each do |s|
    s['count_keep'] = 0
    s['disenchant_note'] = ''
  end
  loot_shards_not_owned = loot_shards.reject { |s| s['redeemableStatus'] == 'ALREADY_OWNED' }

  if loot_shards_not_owned.empty?
    puts "Found no shards of champions you don't own yet.".light_blue
  elsif ans_y.include? user_input_check(
    "Keep a shard for champions you don't own yet?",
    ans_yn,
    ans_yn_d
  )
    loot_shards.each do |l|
      unless l['redeemableStatus'] == 'ALREADY_OWNED'
        l['count'] -= 1
        l['count_keep'] += 1
      end
    end
  end

  loot_shards
rescue StandardError => e
  handle_exception(e, 'Owned Champion Shards')
end
