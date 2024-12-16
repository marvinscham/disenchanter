# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |_repo| 'https://github.com/marvinscham/disenchanter.git' }
ruby '3.2.6'

gem 'base64', '~> 0.2'
gem 'bundler', '~> 2.5.10'
gem 'colorize', '~> 1.1'
gem 'i18n', '~> 1.14'
gem 'json', '~> 2.8'
gem 'launchy', '~> 2' # >3 breaks
gem 'openssl', '~> 3.1.0' # >3.2 won't install
gem 'open-uri', '~> 0.5.0'
gem 'win32-shortcut', '~> 0.3.0'

group :development do
  gem 'i18n-tasks', '~> 1.0.14', require: false
  # Builds windows executable
  gem 'ocran', '1.3.16', require: false
  # Ruby linter, config in .rubocop
  gem 'rubocop', '~> 1.69', require: false
end
