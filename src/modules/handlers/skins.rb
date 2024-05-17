# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for skin shards and permanents
# @param client Client connector
# @param accept Auto-accept level
def handle_skins(client, accept = 0)
  handle_generic(client, I18n.t(:'loot.skin_shards'), Dictionary::SKIN_SHARD, accept)
  handle_generic(client, I18n.t(:'loot.skin_permanents'), Dictionary::SKIN_PERMANENT, accept)
end
