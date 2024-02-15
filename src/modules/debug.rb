# frozen_string_literal: true

def handle_debug(client)
  done = false
  things_todo = {
    '1' => 'Write player_loot to file',
    '2' => 'Write recipes of lootId to file',
    '3' => 'Write loot info of lootId to file',
    'm' => 'Enable debug mode',
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
        "\nWhat would you like to do?\n\n".light_cyan + todo_string +
          'Option: '.white,
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
      player_loot = client.req_get_player_loot
      File.write('disenchanter_loot.json', player_loot.to_json)
      puts('Okay, written to disenchanter_loot.json.')
    when '2'
      loot_id = ask("Which lootId would you like the recipes for?\n".light_cyan)
      recipes = client.req_get_recipes_for_item(loot_id)
      File.write('disenchanter_recipes.json', recipes.to_json)
      puts('Okay, written to disenchanter_recipes.json.')
    when '3'
      loot_id = ask("Which lootId would you like the info for?\n".light_cyan)
      loot_info = client.req_get_loot_info(loot_id)
      File.write('disenchanter_lootinfo.json', loot_info.to_json)
      puts('Okay, written to disenchanter_lootinfo.json.')
    when 'm'
      client.debug = true
      puts 'Debug mode enabled.'
    when 'x'
      done = true
    end
    puts separator
  end
end
