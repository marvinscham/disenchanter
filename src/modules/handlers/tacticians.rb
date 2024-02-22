# frozen_string_literal: true

require_relative '../../class/dictionary'
require_relative 'generic_loot'

# Wrapper for tacticians
# @param client Client connector
# @note There are no shards for tacticians, only permanents
def handle_tacticians(client)
  handle_generic(client, I18n.t(:'loot.tacticians'), Dictionary::TACTICIAN)
end
