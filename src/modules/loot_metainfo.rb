# frozen_string_literal: true

def count_loot_items(loot_items)
  count = 0
  unless loot_items.nil? || loot_items.empty?
    loot_items.each { |loot| count += loot['count'] }
  end
  count
end

def get_chest_name(loot_id)
  chest_info = get_loot_info(loot_id)
  return chest_info['localizedName'] if !chest_info['localizedName'].empty?

  catalogue = {
    'CHEST_128' => 'Champion Capsule',
    'CHEST_129' => 'Glorious Champion Capsule',
    'CHEST_210' => 'Honor Level 4 Orb',
    'CHEST_211' => 'Honor Level 5 Orb',
  }

  return catalogue[loot_id] if catalogue.key?(loot_id)

  return loot_id
end