# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for ward skins and their permanents
# @param client Client connector
def handle_ward_skins(client)
  handle_generic(client, 'Ward Skin Shards', Dictionary::WARD_SKIN_SHARD)
  handle_generic(client, 'Ward Skin Permanents', Dictionary::WARD_SKIN_PERMANENT)
end
