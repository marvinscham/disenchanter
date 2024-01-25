# frozen_string_literal: true

def check_update(version_local)
  begin
    uri =
      URI(
        'https://api.github.com/repos/marvinscham/disenchanter/releases/latest'
      )
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new(uri, "Content-Type": 'application/json')
    res = http.request req
    ans = JSON.parse(res.body)

    version_local =
      Gem::Version.new(version_local.delete_prefix('v').delete_suffix('-beta'))
    version_remote =
      Gem::Version.new(
        ans['tag_name'].delete_prefix('v').delete_suffix('-beta')
      )

    if version_remote > version_local
      puts "New version #{ans['tag_name']} available!".light_yellow
      if ($ans_y).include? user_input_check(
        'Would you like to download the new version now?',
        $ans_yn,
        $ans_yn_d
      )
        `curl https://github.com/marvinscham/disenchanter/releases/download/#{ans['tag_name']}/disenchanter_up.exe -L -o disenchanter_up.exe`
        puts 'Done downloading!'.green

        pid = spawn("start cmd.exe @cmd /k \"disenchanter_up.exe\"")
        Process.detach(pid)
        puts 'Exiting...'.light_black
        exit
      end
    elsif version_local > version_remote
      puts 'Welcome to the future!'.light_magenta
      puts "Latest remote version: v#{version_remote}".light_blue
    else
      puts "You're up to date!".green
    end
  rescue => exception
    handle_exception(exception, 'self update')
  end
end
