# frozen_string_literal: true

require_relative 'open_url'

def setup_locale(client)
  I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

  # $0/$PROGRAM_NAME runs relative to running script instead of working directory
  # File.expand_path will therefore only work locally but not in Ocran
  I18n.load_path += Dir["#{$PROGRAM_NAME}/../../i18n/*.yml"]

  I18n.default_locale = :en
  I18n.fallbacks = I18n::Locale::Fallbacks.new
  I18n.fallbacks.defaults = [:en]

  user_locale = map_locale(client.locale)
  I18n.locale = user_locale

  puts I18n.t(:'meta.auto_loaded_locale').light_white
  puts I18n.t(:'meta.translation_note', url: translation_url).light_yellow
rescue StandardError
  LanguageMenu.new(client).run_loop
end

def map_locale(locale)
  dictionary = {
    en_GB: 'en',
    en_US: 'en'
  }

  return dictionary[locale] if dictionary.key?(locale)

  locale
end
