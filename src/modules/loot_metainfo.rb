# frozen_string_literal: true

def count_loot_items(loot_items)
  count = 0
  return count if loot_items.nil? || loot_items.empty?

  loot_items.each { |loot| count += loot['count'] }
  count
end

def get_chest_name(client, loot_id)
  chest_info = client.req_get_loot_info(loot_id)
  return chest_info['localizedName'] unless chest_info['localizedName'].empty?

  catalogue = {
    'CHEST_128' => I18n.t(:'loot.champion_capsule'),
    'CHEST_129' => I18n.t(:'loot.glorious_champion_capsule'),
    'CHEST_210' => I18n.t(:'loot.honor_4_orb'),
    'CHEST_211' => I18n.t(:'loot.honor_5_orb')
  }

  return catalogue[loot_id] if catalogue.key?(loot_id)

  loot_id
end
