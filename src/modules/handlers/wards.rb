# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for ward skins and their permanents
# @param client Client connector
# @param accept Auto-accept level
def handle_ward_skins(client, accept = 0)
  handle_generic(client, 'Ward Skin Shards', Dictionary::WARD_SKIN_SHARD, accept)
  handle_generic(client, 'Ward Skin Permanents', Dictionary::WARD_SKIN_PERMANENT, accept)
end
