# frozen_string_literal: true

# Wrapper for skin shards and permanents
# @param client Client connector
def handle_skins(client)
  handle_generic(client, 'Skin Shards', 'SKIN_RENTAL')
  handle_generic(client, 'Skin Permanents', 'SKIN')
end
