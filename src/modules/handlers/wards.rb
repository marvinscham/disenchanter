# frozen_string_literal: true

def handle_ward_skins
  handle_generic(
    'Ward Skin Shards',
    'WARDSKIN_RENTAL',
    'WARDSKIN_RENTAL_disenchant'
  )
  handle_generic('Ward Skin Permanents', 'WARDSKIN', 'WARDSKIN_disenchant')
end
