# frozen_string_literal: true

require_relative 'materials/capsules'
require_relative 'materials/key_fragments'
require_relative 'materials/mastery_tokens'
require_relative 'materials/mythic_essence'

# Handles anything from the 'materials' loot section like keys, capsules and more
# @param client Client connector
def handle_materials(client)
  done = false
  things_done = []

  until done
    todo = user_input_check(
      "\nWhat would you like to do?\n\n".light_cyan +
        materials_todo_str(things_done) + ' Option: '.white,
      materials_todo.keys,
      '',
      ''
    )

    things_done << todo
    puts separator + "\n\nOption chosen: #{materials_todo[todo]}".light_white
    done = handle_material_option(todo, client)
    puts separator
  end
end

# Returns a hash with all possible Options and their menu item names
def materials_todo
  {
    '1' => 'Mythic Essence',
    '2' => 'Key Fragments',
    '3' => 'Capsules',
    '4' => 'Mastery Tokens',
    'x' => 'Back to main menu'
  }
end

# Outputs things to do as a pretty string, done things are marked accordingly
# @param things_done Options already processed
def materials_todo_str(things_done)
  todo_string = ''
  materials_todo.each do |k, v|
    todo_string += "[#{k}] ".light_white
    todo_string += if things_done.include? k
                     "#{v} (done)\n".light_green
                   else
                     "#{v}\n".light_cyan
                   end
  end

  todo_string
end

# Calls the corresponding material method
# @param thing_todo Option name
# @return true if done
def handle_material_option(thing_todo, client)
  case thing_todo
  when '1'
    handle_mythic_essence(client)
  when '2'
    handle_key_fragments(client)
  when '3'
    handle_capsules(client)
  when '4'
    handle_mastery_tokens(client)
  when 'x'
    return true
  end

  false
end