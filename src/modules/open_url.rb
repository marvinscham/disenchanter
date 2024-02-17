# frozen_string_literal: true

require 'launchy'

def open_github
  puts 'Opening GitHub repository at https://github.com/marvinscham/disenchanter/ in your browser...'.light_blue
  Launchy.open('https://github.com/marvinscham/disenchanter/')
end

def open_stats
  puts 'Opening Global Stats at https://github.com/marvinscham/disenchanter/wiki/Stats in your browser...'.light_blue
  Launchy.open('https://github.com/marvinscham/disenchanter/wiki/Stats')
end

def open_masterychart(client)
  server = ask("Which server do you play on (EUW/NA/BR/TR...)?\n".light_cyan)
  player = client.req_get_current_summoner
  url = "https://masterychart.com/profile/#{server}/#{player['gameName']}-#{player['tagLine']}?ref=disenchanter"
  puts "Opening your profile at #{url} in your browser...".light_blue
  Launchy.open(url)
end
