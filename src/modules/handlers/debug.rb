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
  puts('Okay, written to disenchanter_loot.json.')
end

def debug_save_recipe(client)
  loot_id = ask("Which lootId would you like the recipes for?\n".light_cyan)
  recipes = client.req_get_recipes_for_item(loot_id)
  File.write('disenchanter_recipes.json', recipes.to_json)
  puts('Okay, written to disenchanter_recipes.json.')
end

def debug_save_loot_info(client)
  loot_id = ask("Which lootId would you like the info for?\n".light_cyan)
  loot_info = client.req_get_loot_info(loot_id)
  File.write('disenchanter_lootinfo.json', loot_info.to_json)
  puts('Okay, written to disenchanter_lootinfo.json.')
end

def debug_save_summoner_info(client)
  File.write('disenchanter_summoner.json', client.req_get_current_summoner.to_json)
  puts('Okay, written to disenchanter_summoner.json.')
end

def debug_save_settings(client)
  File.write('disenchanter_settings.json', client.req_get_settings.to_json)
  puts('Okay, written to disenchanter_settings.json.')
end

def debug_request_terminal(client)
  done = false
  puts(
    'Manual request terminal entered. If you don\'t know what you\'re doing ' \
    'or someone is urging you to do this, stop now.'.light_red
  )
  puts('Press [x] to leave'.light_white)

  until done
    request_path = ask "Enter path to GET from:\n"

    return if request_path == 'x'

    puts JSON.pretty_generate(client.request_get(request_path))
  end
end
