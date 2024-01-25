# frozen_string_literal: true

require_relative 'materials/capsules'
require_relative 'materials/key_fragments'
require_relative 'materials/mastery_tokens'
require_relative 'materials/mythic_essence'

def handle_materials
  done = false
  things_todo = {
    '1' => 'Mythic Essence',
    '2' => 'Key Fragments',
    '3' => 'Capsules',
    '4' => 'Mastery Tokens',
    'x' => 'Back to main menu',
  }
  things_done = []

  until done
    todo_string = ''
    things_todo.each do |k, v|
      todo_string += "[#{k}] ".light_white
      unless things_done.include? k
        todo_string += "#{v}\n".light_cyan
      else
        todo_string += "#{v} (done)\n".light_green
      end
    end

    todo =
      user_input_check(
        "\nWhat would you like to do?\n\n".light_cyan + todo_string +
          'Option: ',
        things_todo.keys,
        '',
        ''
      )
    things_done << todo

    puts $sep
    puts

    puts "Option chosen: #{things_todo[todo]}".light_white

    case todo
    when '1'
      handle_mythic_essence
    when '2'
      handle_key_fragments
    when '3'
      handle_capsules
    when '4'
      handle_mastery_tokens
    when 'x'
      done = true
    end
    puts $sep
  end
end
