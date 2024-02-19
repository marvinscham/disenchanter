# frozen_string_literal: true

# An interactive terminal menu
class Menu
  attr_reader :things_todo

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

  # Runs a menu loop until it's either done or the user bails to the main menu
  # @return true if user bailed
  def run_loop
    done = false
    bail = false

    until done || bail
      thing_todo = user_input_check(
        "\n#{@menu_text}\n\n".light_cyan + todo_str,
        @things_todo.keys,
        @answer_display,
        @client.dry_run ? 'dry' : 'default'
      )
      @things_done << thing_todo
      puts separator + "\n\n#{I18n.t(:'menu.option_chosen')}: #{@things_todo[thing_todo]}".light_white

      done = handle_option(thing_todo)
      bail = thing_todo == 'x'

      puts separator
    end

    bail
  end

  def todo_str
    todo_string = ''
    @things_todo.each do |k, v|
      todo_string += "[#{k}] ".light_white
      todo_string += if @things_done.include? k
                       "#{v} (#{I18n.t(:'menu.option_done')})\n".light_green
                     else
                       "#{v}\n".light_cyan
                     end
    end

    todo_string
  end

  # Override this!
  def handle_option(thing_todo)
    puts "Stump for option: #{thing_todo}."
  end
end
