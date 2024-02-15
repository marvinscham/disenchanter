# frozen_string_literal: true

# Wrapper for summoner icons
# @param client Client connector
# @note No shards for icons!
def handle_icons(client)
  handle_generic(client, 'Icons', 'SUMMONERICON')
end
