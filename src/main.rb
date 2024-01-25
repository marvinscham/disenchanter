#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/https'
require 'base64'
require 'json'
require 'colorize'
require 'launchy'
require 'open-uri'
require 'rbconfig'

require_relative 'modules/client_api'
require_relative 'modules/common_strings'
require_relative 'modules/debug'
require_relative 'modules/handlers'
require_relative 'modules/loot_metainfo'
require_relative 'modules/open_url'
require_relative 'modules/stat_submission'
require_relative 'modules/user_input'

require_relative 'modules/update/checker'
require_relative 'modules/detect_client'

def run
  if File.exist?('./build/.build.lockfile')
    puts 'Detected build environment, skipping execution...'.light_yellow
    sleep 2
    exit
  end

  set_globals
  current_version = 'v1.6.0'

  puts 'Hi! :)'.light_green
  puts "Running Disenchanter #{current_version} on port #{$port}".light_blue
  puts 'You can exit this script at any point by pressing '.light_blue +
         '[CTRL + C]'.light_white + '.'.light_blue
  check_update(current_version)
  puts separator

  summoner = get_current_summoner
  if summoner['gameName'].nil? || summoner['gameName'].empty?
    puts 'Could not grab summoner info. Try restarting your League Client.'.light_red
    ask exit_string
    exit 1
  end
  puts "\nYou're logged in as #{summoner['gameName']} ##{summoner['tagLine']}.".light_blue
  puts separator
  puts "\nFeel free to try the options, no actions will be taken until you confirm a banner like this:".light_blue
  puts 'CONFIRM: Perform this action? [y|n]'.light_magenta
  puts separator

  done = false
  things_todo = {
    '1' => 'Materials',
    '2' => 'Champions',
    '3' => 'Skins',
    #"4" => "Tacticians",
    '5' => 'Eternals',
    '6' => 'Emotes',
    '7' => 'Ward Skins',
    '8' => 'Icons',
    's' => 'Open Disenchanter Global Stats',
    'r' => 'Open GitHub repository',
    'd' => 'Debug Tools',
    'x' => 'Exit',
  }
  things_done = []

  until done
    todo_string = ''
    things_todo.each do |k, v|
      todo_string += "[#{k}] ".light_white
      if things_done.include? k
        todo_string += "#{v} (done)\n".light_green
      else
        todo_string += "#{v}\n".light_cyan
      end
    end

    todo =
      user_input_check(
        "\nWhat would you like to do? (Hint: do Materials first so you don't miss anything!)\n\n".light_cyan +
          todo_string + 'Option: ',
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
      handle_materials
    when '2'
      handle_champions
    when '3'
      handle_skins
      # when "4"
      #   handle_tacticians
    when '5'
      handle_eternals
    when '6'
      handle_emotes
    when '7'
      handle_ward_skins
    when '8'
      handle_icons
    when 's'
      open_stats
    when 'r'
      open_github
    when 'd'
      handle_debug
    when 'x'
      done = true
    end
    refresh_loot
    puts separator
  end

  puts "That's it!".light_green
  if $actions > 0
    puts "We saved you about #{$actions * 3} seconds of waiting for animations to finish.".light_green
    puts separator
  end
  handle_stat_submission
  puts 'See you next time :)'.light_green
  ask exit_string
end

def pad(str, len, right = true)
  "%#{right ? '-' : ''}#{len}s" % str
end

def set_globals
  begin
    $port, $token = grab_lockfile
  rescue StandardError
    puts 'Could not grab session!'.light_red
    puts 'Make sure the script is in your League Client folder and that your Client is running.'.light_red
    ask exit_string
    exit 1
  end
  $host = "https://127.0.0.1:#{$port}"
  $debug = false

  $actions = 0
  $s_disenchanted = 0
  $s_opened = 0
  $s_crafted = 0
  $s_redeemed = 0
  $s_blue_essence = 0
  $s_orange_essence = 0

  $ans_yn = %w[y yes n no]
  $ans_y = %w[y yes]
  $ans_n = %w[n no]
  $ans_yn_d = '[y|n]'
end

run
