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
    menu_text = I18n.t(:'menu.main.what_to_do')

    lang_supp_text = if I18n.t(:'menu.main.options.language_settings') == 'Language settings'
                       ''
                     else
                       ' (Language settings)'
                     end

    things_todo = {
      '1' => I18n.t(:'loot.materials'),
      '2' => I18n.t(:'loot.champions'),
      '3' => I18n.t(:'loot.skins'),
      '4' => I18n.t(:'loot.tacticians'),
      '5' => I18n.t(:'loot.eternals'),
      '6' => I18n.t(:'loot.emotes'),
      '7' => I18n.t(:'loot.ward_skins'),
      '8' => I18n.t(:'loot.icons'),
      'l' => I18n.t(:'menu.main.options.language_settings') + lang_supp_text,
      'm' => I18n.t(:'menu.main.options.open_mastery_chart'),
      's' => I18n.t(:'menu.main.options.open_usage_stats'),
      'r' => I18n.t(:'menu.main.options.open_repository'),
      'd' => 'Debug Tools',
      'x' => I18n.t(:'menu.main.options.exit')
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
      swap_language
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
    false
  end

  def swap_language
    LanguageMenu.new(@client).run_loop
    initialize(@client) # Reload is required to replace menu in old language
    @client.greet
  end
end
