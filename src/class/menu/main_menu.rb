# frozen_string_literal: true

require_relative 'menu'

require_relative '../../modules/handlers/champions'
require_relative '../../modules/handlers/emotes'
require_relative '../../modules/handlers/eternals'
require_relative '../../modules/handlers/exception'
require_relative '../../modules/handlers/icons'
require_relative '../../modules/handlers/skins'
require_relative '../../modules/handlers/tacticians'
require_relative '../../modules/handlers/wards'
require_relative '../../modules/handlers/debug'
require_relative '../../modules/handlers/materials'

require_relative '../../modules/open_url'
require_relative '../../modules/stat_submission'

# The main menu
class MainMenu < Menu
  def initialize(client)
    menu_text = 'What would you like to do? (Hint: go top to bottom so you don\'t miss anything!)'
    things_todo = {
      '1' => 'Materials',
      '2' => 'Champions',
      '3' => 'Skins',
      '4' => 'Tacticians',
      '5' => 'Eternals',
      '6' => 'Emotes',
      '7' => 'Ward Skins',
      '8' => 'Icons',
      'l' => 'Language settings',
      'm' => 'Open Mastery Chart profile',
      's' => 'Open Disenchanter Global Stats',
      'r' => 'Open GitHub repository',
      'd' => 'Debug Tools',
      'x' => 'Exit'
    }
    answer_display = 'Option'

    super(client, menu_text, answer_display, things_todo)
  end

  def handle_option(todo)
    case todo
    when '1'
      handle_materials(@client)
    when '2'
      handle_champions(@client)
    when '3'
      handle_skins(@client)
    when '4'
      handle_tacticians(@client)
    when '5'
      handle_eternals(@client)
    when '6'
      handle_emotes(@client)
    when '7'
      handle_ward_skins(@client)
    when '8'
      handle_icons(@client)
    when 'l'
      LanguageMenu.new(@client).run_loop
    when 'm'
      open_masterychart(@client)
    when 's'
      open_stats
    when 'r'
      open_github
    when 'd'
      handle_debug(@client)
    when 'x'
      return true
    else
      return false
    end

    @client.refresh_loot
    puts separator
    false
  end
end
