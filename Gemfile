# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |_repo| 'https://github.com/marvinscham/disenchanter.git' }
ruby '3.2.3'

gem 'base64', '~> 0.2'
gem 'colorize', '~> 1.1'
gem 'i18n', '~> 1.14'
gem 'json', '~> 2.6'
gem 'launchy', '~> 2.5'
gem 'openssl', '3.1.0' # Reverted from 3.2.0 since it couldnt install
gem 'open-uri', '~> 0.4.1'
gem 'win32-shortcut', '~> 0.3.0'

group :development do
  # Builds windows executable
  gem 'ocran', '1.3.15', require: false
  # Ruby linter, config in .rubocop
  gem 'rubocop', '~> 1.61', require: false
end
