# frozen_string_literal: true

require_relative 'menu'

# An interactive debug menu
class DebugMenu < Menu
  def initialize(client)
    menu_text = I18n.t(:'menu.what_to_do')
    things_todo = {
      '1' => 'Write player_loot to file',
      '2' => 'Write recipes of loodId to file',
      '3' => 'Write loot_info of lootId to file',
      '4' => 'Write summoner info to file',
      '5' => 'Write settings to file',
      'd' => 'Toggle dry run',
      'm' => 'Toggle debug mode',
      't' => 'Request terminal',
      'x' => I18n.t(:'menu.back_to_main')
    }
    answer_display = I18n.t(:'menu.option')

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
      puts "Dry run #{@client.dry_run ? 'enabled' : 'disabled'}"
    when 'm'
      @client.debug = !@client.debug
      puts "Debug mode #{@client.debug ? 'enabled' : 'disabled'}"
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
