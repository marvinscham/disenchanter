#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'net/https'
require 'base64'
require 'json'
require 'colorize'
require 'open-uri'
require_relative 'modules/update/backwards_compat'
require_relative 'modules/update/download'

puts 'Grabbing latest version of Disenchanter...'.light_blue

def run
  if File.exist?('./build/.build.lockfile')
    puts 'Detected build environment, skipping execution...'.light_yellow
    sleep 2
    exit
  end

  backwards_compat
  download_new_version

  pid = spawn('start cmd.exe @cmd /k "disenchanter.exe"')
  Process.detach(pid)
  puts 'Exiting...'.light_black
end

run
