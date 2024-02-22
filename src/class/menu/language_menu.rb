# frozen_string_literal: true

require_relative 'menu'
require_relative '../../modules/open_url'

# Manual language selection menu
class LanguageMenu < Menu
  def initialize(client)
    menu_text = 'What\'s your preferred language?'
    things_todo = {
      'en' => 'English',
      'de' => 'Deutsch',
      'eo' => 'Esperanto',
      'x' => 'Back to main menu'
    }
    answer_display = 'Option'

    super(client, menu_text, answer_display, things_todo)
  end

  # Applies the language the user selected
  # @param thing_todo Language code
  # @return true if done
  def handle_option(thing_todo)
    I18n.locale = case thing_todo
                  when 'de'
                    'de_DE'
                  when 'eo'
                    'eo'
                  else
                    'en'
                  end
    puts I18n.t(:'meta.manually_set_locale')
    puts I18n.t(:'meta.translation_note', url: translation_url).light_yellow

    true
  end
end
