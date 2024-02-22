# frozen_string_literal: true

require_relative 'menu'

# An interactive debug menu
class DebugMenu < Menu
  def initialize(client)
    menu_text = I18n.t(:'menu.what_to_do')
    things_todo = {
      '1' => I18n.t(:'menu.debug.options.loot_to_file'),
      '2' => I18n.t(:'menu.debug.options.recipes_to_file'),
      '3' => I18n.t(:'menu.debug.options.loot_info_to_file'),
      '4' => I18n.t(:'menu.debug.options.summoner_info_to_file'),
      '5' => I18n.t(:'menu.debug.options.settings_to_file'),
      'd' => I18n.t(:'menu.debug.options.toggle_dry_run'),
      'm' => I18n.t(:'menu.debug.options.toggle_debug_mode'),
      't' => I18n.t(:'menu.debug.options.request_terminal'),
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
      puts @client.dry_run ? I18n.t(:'menu.debug.dry_run.enabled') : I18n.t(:'menu.debug.dry_run.disabled')
    when 'm'
      @client.debug = !@client.debug
      puts @client.debug ? I18n.t(:'menu.debug.debug_mode.enabled') : I18n.t(:'menu.debug.debug_mode.disabled')
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
