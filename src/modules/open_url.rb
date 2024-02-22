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
  server = ask("Which server do you play on (EUW/NA/BR/TR...)?\n".light_cyan)
  player = client.req_get_current_summoner
  url = "https://masterychart.com/profile/#{server}/#{player['gameName']}-#{player['tagLine']}?ref=disenchanter"
  puts I18n.t(:'handler.url.opening_mastery_chart', url:).light_blue
  Launchy.open(url)
end

def translation_url
  "https://github.com/marvinscham/disenchanter/blob/main/CONTRIBUTING.md"
end