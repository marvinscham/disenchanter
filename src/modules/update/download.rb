# frozen_string_literal: true

def download_new_version
  ans = fetch_newest_release

  puts "Downloading Disenchanter #{ans['tag_name']}".light_green
  `curl https://github.com/marvinscham/disenchanter/releases/download/#{ans['tag_name']}/disenchanter.exe \
    -L -o disenchanter.exe`

  puts '____________________________________________________________'.light_black
  puts 'Done downloading!'.green
end

def fetch_newest_release
  uri = URI('https://api.github.com/repos/marvinscham/disenchanter/releases/latest')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Get.new(uri, 'Content-Type': 'application/json')
  res = http.request req
  JSON.parse(res.body)
end
