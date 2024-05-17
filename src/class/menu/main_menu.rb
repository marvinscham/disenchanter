# frozen_string_literal: true

require_relative 'menu'
require_relative 'detail_menu'

require_relative '../../modules/handlers/mass'
require_relative '../../modules/handlers/debug'

require_relative '../../modules/open_url'
require_relative '../../modules/stat_submission'

# The main menu
class MainMenu < Menu
  def initialize(client)
    menu_text = I18n.t('menu.what_to_do')

    lang_supp_text = if I18n.t(:'menu.main.options.language_settings') == 'Language settings'
                       ''
                     else
                       ' (Language settings)'
                     end

    things_todo = {
      '1' => I18n.t(:'loot.soft'),
      '2' => I18n.t(:'loot.hard'),
      '3' => I18n.t(:'loot.detailed'),
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
      handle_mass(@client, 1)
      return true
    when '2'
      handle_mass(@client, 2)
      return true
    when '3'
      DetailMenu.new(@client).run_loop
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
