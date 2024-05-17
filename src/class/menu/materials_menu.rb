# frozen_string_literal: true

require_relative 'menu'

require_relative '../../modules/handlers/mythic_essence'
require_relative '../../modules/handlers/key_fragments'
require_relative '../../modules/handlers/capsules'

# Menu for handling materials such as fragments, mythic essence or capsules
class MaterialsMenu < Menu
  def initialize(client)
    menu_text = I18n.t(:'menu.what_to_do')
    things_todo = {
      '1' => I18n.t(:'menu.materials.options.mythic_essence'),
      '2' => I18n.t(:'menu.materials.options.key_fragments'),
      '3' => I18n.t(:'menu.materials.options.capsules'),
      'x' => I18n.t(:'menu.back_to_detail')
    }
    answer_display = I18n.t(:'menu.option')

    super(client, menu_text, answer_display, things_todo)
  end

  # Calls the corresponding material handling method
  # @param thing_todo Option name
  # @return true if done
  def handle_option(thing_todo)
    case thing_todo
    when '1'
      handle_mythic_essence(@client)
    when '2'
      handle_key_fragments(@client)
    when '3'
      handle_capsules(@client)
    when 'x'
      return true
    else
      return false
    end

    false
  end
end
