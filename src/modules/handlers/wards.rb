# frozen_string_literal: true

require_relative 'generic_loot'

# Wrapper for ward skins and their permanents
# @param client Client connector
def handle_ward_skins(client)
  handle_generic(client, 'Ward Skin Shards', 'WARDSKIN_RENTAL')
  handle_generic(client, 'Ward Skin Permanents', 'WARDSKIN')
end
