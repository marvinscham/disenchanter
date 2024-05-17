# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for eternals sets and their shards
# @param client Client connector
# @param accept Auto-accept level
def handle_eternals(client, accept = 0)
  handle_generic(client, I18n.t(:'loot.eternal_shards'), Dictionary::ETERNAL_SHARD, accept)
  handle_generic(client, I18n.t(:'loot.eternal_permanents'), Dictionary::ETERNAL_PERMANENT, accept)
end
