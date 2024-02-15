# frozen_string_literal: true

# Wrapper for eternals sets and their shards
# @param client Client connector
def handle_eternals(client)
  handle_generic(client, 'Eternals Set Shards', 'STATSTONE_SHARD')
  handle_generic(client, 'Eternals Set Permanent', 'STATSTONE')
end
