# frozen_string_literal: true

require 'launchy'

def open_github
  url = 'https://github.com/marvinscham/disenchanter/'
  puts I18n.t(:'handler.url.opening_repository', url:).light_blue
  Launchy.open('https://github.com/marvinscham/disenchanter/')
end

def open_stats
  url = 'https://github.com/marvinscham/disenchanter/wiki/Stats'
  puts I18n.t(:'handler.url.opening_stats', url:).light_blue
  Launchy.open('https://github.com/marvinscham/disenchanter/wiki/Stats')
end

def open_masterychart(client)
  player = client.req_get_current_summoner
  region = client.req_get_region

  region = region[0...-1] if region[-1] == '1' || region[-1] == '2'
  region = region.downcase

  url = "https://masterychart.com/profile/#{region}/#{player['gameName']}-#{player['tagLine']}?ref=disenchanter"
  puts I18n.t(:'handler.url.opening_mastery_chart', url:).light_blue
  Launchy.open(url)
end

def translation_url
  'https://github.com/marvinscham/disenchanter/blob/main/CONTRIBUTING.md'
end