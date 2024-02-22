# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for eternals sets and their shards
# @param client Client connector
def handle_eternals(client)
  handle_generic(client, I18n.t(:'loot.eternal_shards'), Dictionary::ETERNAL_SHARD)
  handle_generic(client, I18n.t(:'loot.eternal_permanents'), Dictionary::ETERNAL_PERMANENT)
end
