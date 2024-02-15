#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/https'
require 'base64'
require 'json'
require 'colorize'
require 'launchy'
require 'open-uri'
require 'rbconfig'

require_relative 'class/client'
require_relative 'class/stat_tracker'

require_relative 'modules/common_strings'
require_relative 'modules/debug'
require_relative 'modules/handlers'
require_relative 'modules/loot_metainfo'
require_relative 'modules/open_url'
require_relative 'modules/stat_submission'
require_relative 'modules/user_input'

require_relative 'modules/update/checker'

def run
  if File.exist?('./build/.build.lockfile')
    puts 'Detected build environment, skipping execution...'.light_yellow
    sleep 2
    exit
  end

  current_version = 'v1.6.0'
  stat_tracker = StatTracker.new
  client = Client.new(stat_tracker)

  puts 'Hi! :)'.light_green
  puts "Running Disenchanter #{current_version}".light_blue
  check_update(current_version)
  print 'You can exit this script at any point by pressing '.light_blue
  puts '[CTRL + C]'.light_white + '.'.light_blue
  puts separator

  summoner = client.req_get_current_summoner
  if summoner['gameName'].nil? || summoner['gameName'].empty?
    puts 'Could not grab summoner info. Try restarting your League Client.'.light_red
    ask exit_string
    exit 1
  end
  puts "\nYou're logged in as #{summoner['gameName']} ##{summoner['tagLine']}.".light_blue
  puts separator
  puts "\nYour loot is safe, no actions will be taken until you confirm a banner like this:".light_blue
  puts 'CONFIRM: Perform this action? [y|n]'.light_magenta
  puts separator

  done = false
  things_todo = {
    '1' => 'Materials',
    '2' => 'Champions',
    '3' => 'Skins',
    '4' => 'Tacticians',
    '5' => 'Eternals',
    '6' => 'Emotes',
    '7' => 'Ward Skins',
    '8' => 'Icons',
    's' => 'Open Disenchanter Global Stats',
    'r' => 'Open GitHub repository',
    'd' => 'Debug Tools',
    'x' => 'Exit'
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
        "\nWhat would you like to do? (Hint: go top to bottom so you don't miss anything!)\n\n".light_cyan +
          "#{todo_string}Option: ",
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
      handle_materials(client)
    when '2'
      handle_champions(client)
    when '3'
      handle_skins(client)
    when '4'
      handle_tacticians(client)
    when '5'
      handle_eternals(client)
    when '6'
      handle_emotes(client)
    when '7'
      handle_ward_skins(client)
    when '8'
      handle_icons(client)
    when 's'
      open_stats
    when 'r'
      open_github
    when 'd'
      handle_debug
    when 'x'
      done = true
    end
    client.refresh_loot
    puts separator
  end

  puts "That's it!".light_green
  if stat_tracker.actions.positive?
    puts "We saved you about #{stat_tracker.actions * 3} seconds of waiting for animations to finish.".light_green
    puts separator
  end
  handle_stat_submission(stat_tracker)
  puts 'See you next time :)'.light_green
  ask exit_string
end

run
