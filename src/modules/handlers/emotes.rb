# frozen_string_literal: true

# Wrapper for emotes
# @param client Client connector
# @note No shards for emotes
def handle_emotes(client)
  handle_generic(client, 'Emotes', 'EMOTE')
end
