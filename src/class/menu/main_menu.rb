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
    menu_text = I18n.t(:'main_menu.what_to_do')
    things_todo = {
      '1' => I18n.t(:'main_menu.options.materials'),
      '2' => I18n.t(:'main_menu.options.champions'),
      '3' => I18n.t(:'main_menu.options.skins'),
      '4' => I18n.t(:'main_menu.options.tacticians'),
      '5' => I18n.t(:'main_menu.options.eternals'),
      '6' => I18n.t(:'main_menu.options.emotes'),
      '7' => I18n.t(:'main_menu.options.ward_skins'),
      '8' => I18n.t(:'main_menu.options.icons'),
      'l' => I18n.t(:'main_menu.options.language_settings'),
      'm' => I18n.t(:'main_menu.options.open_mastery_chart'),
      's' => I18n.t(:'main_menu.options.open_usage_stats'),
      'r' => I18n.t(:'main_menu.options.open_repository'),
      'd' => I18n.t(:'main_menu.options.debug_tools'),
      'x' => I18n.t(:'main_menu.options.exit')
    }
    answer_display = I18n.t(:'menu.option')

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
