# frozen_string_literal: true

# Wrapper for skin shards and permanents
# @param client Client connector
def handle_skins(client)
  handle_generic(client, 'Skin Shards', 'SKIN_RENTAL', 'SKIN_RENTAL_disenchant')
  handle_generic(client, 'Skin Permanents', 'SKIN', 'SKIN_disenchant')
end
