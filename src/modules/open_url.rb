# frozen_string_literal: true

def open_github
  puts 'Opening GitHub repository at https://github.com/marvinscham/disenchanter/ in your browser...'.light_blue
  Launchy.open('https://github.com/marvinscham/disenchanter/')
end

def open_stats
  puts 'Opening Global Stats at https://github.com/marvinscham/disenchanter/wiki/Stats in your browser...'.light_blue
  Launchy.open('https://github.com/marvinscham/disenchanter/wiki/Stats')
end
