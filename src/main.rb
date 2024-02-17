#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'class/client'
require_relative 'class/menu/main_menu'
require_relative 'class/stat_tracker'

require_relative 'modules/common_strings'
require_relative 'modules/user_input'

require_relative 'modules/update/checker'

def run
  check_build_env

  current_version = 'v1.6.0'
  stat_tracker = StatTracker.new
  client = Client.new(stat_tracker)

  greet(client, current_version)

  MainMenu.new(client).run_loop

  finish(stat_tracker)
end

def greet(client, current_version)
  puts 'Hi! :)'.light_green
  puts "Running Disenchanter #{current_version}".light_blue
  check_update(current_version)
  print 'You can exit this script at any point by pressing '.light_blue
  puts '[CTRL + C]'.light_white + '.'.light_blue
  puts separator

  check_summoner(client)
end

def check_summoner(client)
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
end

def finish(stat_tracker)
  puts "That's it!".light_green
  if stat_tracker.actions.positive?
    puts "We saved you about #{stat_tracker.actions * 3} seconds of waiting for animations to finish.".light_green
    puts separator
  end
  handle_stat_submission(stat_tracker)
  puts 'See you next time :)'.light_green
  ask exit_string
end

def check_build_env
  return unless File.exist?('./build/.build.lockfile')

  puts 'Detected build environment, skipping execution...'.light_yellow
  sleep 1
  exit
end

run
