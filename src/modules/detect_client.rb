# frozen_string_literal: true

win_ident = /mswin|mingw|cygwin/
require 'win32/registry' if RbConfig::CONFIG['host_os'] =~ win_ident
require 'win32/shortcut' if RbConfig::CONFIG['host_os'] =~ win_ident

include Win32 if RbConfig::CONFIG['host_os'] =~ win_ident

if RbConfig::CONFIG['host_os'] =~ win_ident
  module Win32::Registry::Constants
    KEY_WOW64_64KEY = 0x0100
    KEY_WOW64_32KEY = 0x0200
  end
end

def grab_lockfile
  is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  if is_windows.zero?
    lockfile = 'lockfile'
    puts 'Trying to automatically get the path of the League Client'.green
    begin
      keyname = 'SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Riot Game league_of_legends.live'
      reg = Win32::Registry::HKEY_CURRENT_USER.open(keyname,
                                                    Win32::Registry::KEY_READ | Win32::Registry::KEY_WOW64_32KEY)
      lockfile = "#{reg['InstallLocation']}/lockfile"
    rescue
      # do nothing
    end
    if lockfile == 'lockfile'
      begin
        sc = Shortcut.open('C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Riot Games\\League of Legends.lnk')
        scpath = sc.path.split('\\')
        path = scpath[0..-3].join('\\')
        lockfile = "#{path}\\League of Legends\\lockfile"
      rescue
        # just keep going
      end
    end
  end

  if lockfile == 'lockfile'
    begin
      contents = File.read("C:\\Riot Games\\League of Legends\\#{lockfile}")
    rescue
      puts 'Failed to automatically find your League Client path. ' \
           'Please place the script directly in your League Client folder.'.light_red
      contents = File.read(lockfile)
    end
  else
    contents = File.read(lockfile)
  end

  _leagueclient, _unk_port, port, password = contents.split(':')
  token = Base64.encode64("riot:#{password.chomp}")

  [port, token]
end
