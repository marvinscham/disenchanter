# frozen_string_literal: true

require_relative 'menu'

require_relative '../../modules/handlers/mythic_essence'
require_relative '../../modules/handlers/key_fragments'
require_relative '../../modules/handlers/capsules'
require_relative '../../modules/handlers/mastery_tokens'

# Menu for handling materials such as fragments, mythic essence or capsules
class MaterialsMenu < Menu
  def initialize(client)
    menu_text = 'What would you like to do?'
    things_todo = {
      '1' => 'Mythic Essence',
      '2' => 'Key Fragments',
      '3' => 'Capsules',
      '4' => 'Mastery Tokens',
      'x' => 'Back to main menu'
    }
    answer_display = 'Option'

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
    when '4'
      handle_mastery_tokens(@client)
    when 'x'
      return true
    end

    false
  end
end
