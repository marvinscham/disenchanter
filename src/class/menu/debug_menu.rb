# frozen_string_literal: true

require_relative 'menu'

# An interactive debug menu
class DebugMenu < Menu
  def initialize(client)
    menu_text = 'What would you like to do?'
    things_todo = {
      '1' => 'Write player_loot to file',
      '2' => 'Write recipes of lootId to file',
      '3' => 'Write loot info of lootId to file',
      '4' => 'Write summoner info to file',
      'm' => 'Toggle debug mode',
      'x' => 'Back to main menu'
    }
    answer_display = 'Option'

    super(client, menu_text, answer_display, things_todo)
  end

  # Handles the debug step the user selected
  # @param thing_todo Option name
  # @return true if done
  def handle_option(thing_todo)
    case thing_todo
    when '1'
      player_loot = @client.req_get_player_loot
      File.write('disenchanter_loot.json', player_loot.to_json)
      puts('Okay, written to disenchanter_loot.json.')
    when '2'
      loot_id = ask("Which lootId would you like the recipes for?\n".light_cyan)
      recipes = @client.req_get_recipes_for_item(loot_id)
      File.write('disenchanter_recipes.json', recipes.to_json)
      puts('Okay, written to disenchanter_recipes.json.')
    when '3'
      loot_id = ask("Which lootId would you like the info for?\n".light_cyan)
      loot_info = @client.req_get_loot_info(loot_id)
      File.write('disenchanter_lootinfo.json', loot_info.to_json)
      puts('Okay, written to disenchanter_lootinfo.json.')
    when '4'
      File.write('disenchanter_summoner.json', @client.req_get_current_summoner.to_json)
      puts('Okay, written to disenchanter_summoner.json.')
    when 'm'
      @client.debug = !@client.debug
      puts @client.debug ? 'Debug mode enabled' : 'Debug mode disabled'
    when 'x'
      return true
    end

    false
  end
end
