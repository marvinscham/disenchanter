# frozen_string_literal: true

require 'openssl'

def check_update(version_local)
  tag_name = grab_remote_tag_name

  version_local = Gem::Version.new(version_local.delete_prefix('v').delete_suffix('-beta'))
  version_remote = Gem::Version.new(tag_name.delete_prefix('v').delete_suffix('-beta'))

  if version_remote == version_local
    puts I18n.t(:'update_checker.up_to_date').green
    return
  end

  if version_local > version_remote
    puts I18n.t(:'update_checker.local_beta_note').light_magenta
    puts I18n.t(:'update_checker.local_beta_version', version: version_remote).light_blue
    return
  end

  puts I18n.t(:'update_checker.update_available', version: version_remote).light_yellow
  download_remote_version(tag_name)
rescue StandardError => e
  handle_exception(e, 'self update')
end

def grab_remote_tag_name
  uri = URI('https://api.github.com/repos/marvinscham/disenchanter/releases/latest')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Get.new(uri, 'Content-Type': 'application/json')
  res = http.request req
  JSON.parse(res.body)['tag_name']
end

# Downloads the specified version from GitHub
# @param version Disenchanter version to download
def download_remote_version(version)
  if ans_y.include? user_input_check(
    I18n.t(:'update_checker.ask_download_now'),
    ans_yn,
    ans_yn_d
  )
    exe_url = "https://github.com/marvinscham/disenchanter/releases/download/#{version}/disenchanter_up.exe"
    `curl #{exe_url} -L -o disenchanter_up.exe`
    puts I18n.t(:'update_checker.done_downloading').green

    pid = spawn('start cmd.exe @cmd /k "disenchanter_up.exe"')
    Process.detach(pid)
    puts I18n.t(:'common.exiting').light_black
    exit
  end
end
