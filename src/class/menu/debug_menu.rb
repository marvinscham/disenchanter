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
      '5' => 'Write settings to file',
      'd' => 'Toggle dry run',
      'm' => 'Toggle debug mode',
      't' => 'Request terminal',
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
      debug_save_player_loot(@client)
    when '2'
      debug_save_recipe(@client)
    when '3'
      debug_save_loot_info(@client)
    when '4'
      debug_save_summoner_info(@client)
    when '5'
      debug_save_settings(@client)
    when 'd'
      @client.dry_run = !@client.dry_run
      @client.debug = @client.dry_run
      puts @client.dry_run ? 'Dry run + debug enabled' : 'Dry run + debug disabled'
    when 'm'
      @client.debug = !@client.debug
      puts @client.debug ? 'Debug mode enabled' : 'Debug mode disabled'
    when 't'
      debug_request_terminal(@client)
    when 'x'
      return true
    else
      return false
    end

    false
  end
end
