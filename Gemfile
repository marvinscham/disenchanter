# frozen_string_literal: true
source 'https://rubygems.org'
git_source(:github) { |_repo| 'https://github.com/marvinscham/disenchanter.git' }
ruby '3.2.3'

gem 'base64', '~> 0.2'
gem 'colorize', '~> 1.1'
gem 'json', '~> 2.6'
gem 'launchy', '~> 2.5'
gem 'open-uri', '~> 0.2.0'
gem 'win32-shortcut', '~> 0.3.0'

group :development do
  # Builds windows executable
  gem 'ocra', '1.3.11', require: false
  # Ruby formatter, config in .rufo
  gem 'rufo', '>= 0.13.0', require: false
  # Ruby linter, config in .rubocop
  gem 'rubocop', '~> 1.60', require: false
end

