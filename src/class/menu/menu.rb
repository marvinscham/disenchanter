# frozen_string_literal: true

# An interactive terminal menu
class Menu
  # @param client Client connector
  # @param menu_text Text presented at the menu's top
  # @param answer_display Display text for answers
  # @param things_todo Dict of selectable options
  def initialize(client, menu_text, answer_display, things_todo)
    @client = client
    @menu_text = menu_text
    @answer_display = answer_display
    @things_todo = things_todo

    @things_done = []
  end

  def run_loop
    done = false

    until done
      thing_todo = user_input_check(
        "\n#{@menu_text}\n\n".light_cyan + todo_str,
        @things_todo.keys,
        @answer_display,
        'default'
      )
      @things_done << thing_todo
      puts separator + "\n\nOption chosen: #{@things_todo[thing_todo]}".light_white

      done = handle_option(thing_todo)
      puts separator
    end
  end

  def todo_str
    todo_string = ''
    @things_todo.each do |k, v|
      todo_string += "[#{k}] ".light_white
      todo_string += if @things_done.include? k
                       "#{v} (done)\n".light_green
                     else
                       "#{v}\n".light_cyan
                     end
    end

    todo_string
  end

  # Override this!
  def handle_option(todo)
    puts "Stump for option: #{todo}."
  end
end
