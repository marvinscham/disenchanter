# frozen_string_literal: true

require_relative 'generic_loot'

# Wrapper for skin shards and permanents
# @param client Client connector
def handle_skins(client)
  handle_generic(client, 'Skin Shards', 'SKIN_RENTAL')
  handle_generic(client, 'Skin Permanents', 'SKIN')
end
