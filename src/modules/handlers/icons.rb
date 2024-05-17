# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for summoner icons
# @param client Client connector
# @param accept Auto-accept level
# @note No shards for icons! lootIds are like SUMMONER_ICON_<ID>
def handle_icons(client, accept = 0)
  handle_generic(client, I18n.t(:'loot.icons'), Dictionary::ICON, accept)
end
