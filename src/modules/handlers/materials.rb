# frozen_string_literal: true

require_relative 'materials/capsules'
require_relative 'materials/key_fragments'
require_relative 'materials/mastery_tokens'
require_relative 'materials/mythic_essence'

def handle_materials(client, stat_tracker)
  done = false
  things_todo = {
    '1' => 'Mythic Essence',
    '2' => 'Key Fragments',
    '3' => 'Capsules',
    '4' => 'Mastery Tokens',
    'x' => 'Back to main menu'
  }
  things_done = []

  until done
    todo_string = ''
    things_todo.each do |k, v|
      todo_string += "[#{k}] ".light_white
      todo_string += if things_done.include? k
                       "#{v} (done)\n".light_green
                     else
                       "#{v}\n".light_cyan
                     end
    end

    todo =
      user_input_check(
        "\nWhat would you like to do?\n\n".light_cyan +
          "#{todo_string} Option: ",
        things_todo.keys,
        '',
        ''
      )
    things_done << todo

    puts separator
    puts

    puts "Option chosen: #{things_todo[todo]}".light_white

    case todo
    when '1'
      handle_mythic_essence(client, stat_tracker)
    when '2'
      handle_key_fragments(client, stat_tracker)
    when '3'
      handle_capsules(client, stat_tracker)
    when '4'
      handle_mastery_tokens(client, stat_tracker)
    when 'x'
      done = true
    end
    puts separator
  end
end
