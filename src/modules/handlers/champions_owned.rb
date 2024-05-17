# frozen_string_literal: true

require_relative '../../class/dictionary'

# Keeps a shard for each champion not owned yet
# @param loot_shards Loot array, pre-filtered to only champion shards and permanents
# @param accept Auto-accept level
def handle_champions_owned(loot_shards, accept = 0)
  return loot_shards if accept == 2

  loot_shards.each do |s|
    s['count_keep'] = 0
    s['disenchant_note'] = ''
  end
  loot_shards_not_owned = loot_shards.reject { |s| s['redeemableStatus'] == Dictionary::STATUS_OWNED }

  if loot_shards_not_owned.empty?
    puts I18n.t(:'handler.champion.no_unowned_champs_found').light_blue
  elsif accept == 1 ||
        ans_y.include?(user_input_check(
                         I18n.t(:'handler.champion.ask_keep_unowned_champs'),
                         ans_yn,
                         ans_yn_d
                       ))
    loot_shards.each do |l|
      unless l['redeemableStatus'] == Dictionary::STATUS_OWNED
        l['count'] -= 1
        l['count_keep'] += 1
      end
    end
  end

  loot_shards
rescue StandardError => e
  handle_exception(e, 'champions: owned')
end
