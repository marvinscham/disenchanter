# frozen_string_literal: true

require 'json'
require_relative '../../class/menu/debug_menu'

# Wrapper for debug
# @param client Client connector
def handle_debug(client)
  DebugMenu.new(client).run_loop
end

def debug_save_player_loot(client)
  player_loot = client.req_get_player_loot
  File.write('disenchanter_loot.json', player_loot.to_json)
  puts I18n.t(:'menu.debug.file_written_notice', filename: 'disenchanter_loot.json')
end

def debug_save_recipe(client)
  loot_id = ask("#{I18n.t(:'menu.debug.ask_which_loot_recipes')}\n".light_cyan)
  recipes = client.req_get_recipes_for_item(loot_id)
  File.write('disenchanter_recipes.json', recipes.to_json)
  puts I18n.t(:'menu.debug.file_written_notice', filename: 'disenchanter_recipes.json')
end

def debug_save_loot_info(client)
  loot_id = ask("#{I18n.t(:'menu.debug.ask_which_loot_info')}\n".light_cyan)
  loot_info = client.req_get_loot_info(loot_id)
  File.write('disenchanter_lootinfo.json', loot_info.to_json)
  puts I18n.t(:'menu.debug.file_written_notice', filename: 'disenchanter_lootinfo.json')
end

def debug_save_summoner_info(client)
  File.write('disenchanter_summoner.json', client.req_get_current_summoner.to_json)
  puts I18n.t(:'menu.debug.file_written_notice', filename: 'disenchanter_summoner.json')
end

def debug_save_settings(client)
  File.write('disenchanter_settings.json', client.req_get_settings.to_json)
  puts I18n.t(:'menu.debug.file_written_notice', filename: 'disenchanter_settings.json')
end

def debug_request_terminal(client)
  puts(
    I18n.t(:'menu.debug.request_terminal.warning').light_red
  )
  puts(I18n.t(:'menu.debug.request_terminal.exit', key: 'x').light_white)

  loop do
    request_path = ask "#{I18n.t(:'menu.debug.request_terminal.ask_path')}\n"

    return if request_path == 'x'

    puts JSON.pretty_generate(client.request_get(request_path))
  end
end
