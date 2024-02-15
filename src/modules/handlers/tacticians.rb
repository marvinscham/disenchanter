# frozen_string_literal: true

# Wrapper for tacticians
# @param client Client connector
# @note There are no shards for tacticians, only permanents
def handle_tacticians(client)
  handle_generic(client, 'Tacticians', 'COMPANION')
end
