#!/usr/bin/env ruby
# frozen_string_literal: true

require 'i18n'

require_relative 'class/client'
require_relative 'class/menu/main_menu'
require_relative 'class/menu/language_menu'
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
  puts I18n.t(:'main_menu.hello').light_green

  puts I18n.t(:'main_menu.version_info', version: current_version).light_blue
  check_update(current_version)
  print "#{I18n.t(:'main_menu.exit_shortcut_notice')} ".light_blue
  puts I18n.t(:'main_menu.exit_shortcut').light_white + '.'.light_blue
  puts separator

  check_summoner(client)
end

def check_summoner(client)
  summoner = client.req_get_current_summoner
  if summoner['gameName'].nil? || summoner['gameName'].empty?
    puts I18n.t(:'main_menu.summoner_check_failed').light_red
    ask exit_string
    exit 1
  end

  puts "\n#{I18n.t(:'main_menu.logged_in_as', name: summoner['gameName'], tagline: summoner['tagLine'])}".light_blue
  puts separator
  puts "\n#{I18n.t(:'main_menu.confirm_banner_intro')}".light_blue
  puts "#{I18n.t(:'main_menu.confirm_banner_example')} [y|n]".light_magenta
  puts separator
end

def finish(stat_tracker)
  puts I18n.t(:'main_menu.all_done').light_green
  if stat_tracker.actions.positive?
    puts I18n.t(:'main_menu.time_saved', time_saved: stat_tracker.actions * 3).light_green
    puts separator
  end
  handle_stat_submission(stat_tracker)
  puts I18n.t(:'main_menu.see_you').light_green
  ask exit_string
end

def check_build_env
  return unless File.exist?('./build/.build.lockfile')

  puts 'Detected build environment, skipping execution...'.light_yellow
  sleep 1
  exit
end

run
