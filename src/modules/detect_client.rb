# frozen_string_literal: true

win_ident = /mswin|mingw|cygwin/
require 'win32/registry' if RbConfig::CONFIG['host_os'] =~ win_ident
require 'win32/shortcut' if RbConfig::CONFIG['host_os'] =~ win_ident
require 'date'

# rubocop:disable Style/MixinUsage
include Win32 if RbConfig::CONFIG['host_os'] =~ win_ident
# rubocop:enable Style/MixinUsage

# rubocop:disable Style/ClassAndModuleChildren
if RbConfig::CONFIG['host_os'] =~ win_ident
  module Win32::Registry::Constants
    KEY_WOW64_64KEY = 0x0100
    KEY_WOW64_32KEY = 0x0200
  end
end
# rubocop:enable Style/ClassAndModuleChildren

def grab_lockfile
  is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/).zero?

  if is_windows
    credentials, path = try_grab_lockfile_registry
    credentials, path = try_grab_lockfile_start_menu if credentials == ''
  end

  credentials, path = try_grab_lockfile_default_path if credentials == ''
  credentials, path = try_grab_lockfile_locally if credentials == ''

  _leagueclient, _unk_port, port, password = credentials.split(':')
  token = Base64.encode64("riot:#{password.chomp}")

  [port, token, path]
end

def try_grab_lockfile_registry
  keyname = 'SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Riot Game league_of_legends.live'
  reg = Win32::Registry::HKEY_CURRENT_USER.open(
    keyname,
    Win32::Registry::KEY_READ | Win32::Registry::KEY_WOW64_32KEY
  )

  credentials = File.read("#{reg['InstallLocation']}/lockfile")
  puts 'Found client via registry'.light_black

  [credentials, reg['InstallLocation']]
rescue StandardError
  # Just keep going
  ''
end

def try_grab_lockfile_start_menu
  sc = Shortcut.open(
    'C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Riot Games\\League of Legends.lnk'
  )
  scpath = sc.path.split('\\')
  path = scpath[0..-3].join('\\')

  credentials = File.read("#{path}\\League of Legends\\lockfile")
  puts 'Found client via start menu'.light_black

  [credentials, "#{path}\\League of Legends"]
rescue StandardError
  # Just keep going
  ''
end

def try_grab_lockfile_default_path
  credentials = File.read("C:\\Riot Games\\League of Legends\\#{lockfile}")
  puts 'Found client at standard path'.light_black

  [credentials, 'C:\\Riot Games\\League of Legends']
rescue StandardError
  # Just keep going
  ''
end

def try_grab_lockfile_locally
  credentials = File.read(lockfile)
  puts 'Found client locally'.light_black

  [credentials, '.']
rescue StandardError
  puts 'Failed to automatically find your League Client.'.light_red
  puts 'Make sure your client is running and logged into your account.'.light_red
  puts 'If it\'s running and you\'re seeing this, ' \
       'please place the script directly in your League Client folder.'.light_red
end

def grab_locale(path)
  directory_path = "#{path.gsub('\\', '/')}/Game/DATA/FINAL/Localized"
  files = Dir.glob("#{directory_path}/*")

  sorted_files = files.sort_by { |file| File.mtime(file) }.reverse
  newest_file = sorted_files.first
  locale_match = File.basename(newest_file).match(/\.([a-z]{2}_[A-Z]{2})\./)

  locale_match ? locale_match[1] : 'en'
rescue StandardError
  'en'
end
