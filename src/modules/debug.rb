# frozen_string_literal: true

def handle_debug
  done = false
  things_todo = {
    '1' => 'Write player_loot to file',
    '2' => 'Write recipes of lootId to file',
    '3' => 'Write loot info of lootId to file',
    'm' => 'Enable debug mode',
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
      player_loot = get_player_loot

      File.open('disenchanter_loot.json', 'w') do |f|
        f.write(player_loot.to_json)
      end

      puts('Okay, written to disenchanter_loot.json.')
    when '2'
      loot_id = ask("Which lootId would you like the recipes for?\n".light_cyan)

      recipes = get_recipes_for_item loot_id

      File.open('disenchanter_recipes.json', 'w') do |f|
        f.write(recipes.to_json)
      end

      puts('Okay, written to disenchanter_recipes.json.')
    when '3'
      loot_id = ask("Which lootId would you like the info for?\n".light_cyan)

      loot_info = get_loot_info loot_id

      File.open('disenchanter_lootinfo.json', 'w') do |f|
        f.write(loot_info.to_json)
      end

      puts('Okay, written to disenchanter_lootinfo.json.')
    when 'm'
      $debug = true
      puts 'Debug mode enabled.'
    when 'x'
      done = true
    end
    puts $sep
  end
end
