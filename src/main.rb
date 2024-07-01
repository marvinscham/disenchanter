#!/usr/bin/env ruby
# frozen_string_literal: true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'bundler/setup'
require 'i18n'

require_relative 'class/client'
require_relative 'class/menu/main_menu'
require_relative 'class/menu/language_menu'
require_relative 'class/stat_tracker'

require_relative 'modules/common_strings'
require_relative 'modules/user_input'

def run
  check_build_env

  current_version = 'v2.0.1'
  stat_tracker = StatTracker.new
  client = Client.new(stat_tracker, current_version)

  client.greet
  client.check_summoner

  MainMenu.new(client).run_loop

  finish(stat_tracker)
end

def finish(stat_tracker)
  puts I18n.t(:'menu.main.all_done').light_green
  if stat_tracker.actions.positive?
    puts I18n.t(:'menu.main.time_saved', time_saved: stat_tracker.actions * 3).light_green
    puts separator
  end
  handle_stat_submission(stat_tracker)
  puts I18n.t(:'menu.main.see_you').light_green
  ask exit_string
end

def check_build_env
  return unless File.exist?('./build/.build.lockfile')

  puts 'Detected build environment, skipping execution...'.light_yellow
  sleep 1
  exit
end

run
