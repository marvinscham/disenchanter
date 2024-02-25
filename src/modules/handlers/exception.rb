# frozen_string_literal: true

def handle_exception(exception, name)
  issue_url = 'https://github.com/marvinscham/disenchanter/issues/new'
  dev_email = 'dev@marvinscham.de'

  puts I18n.t(:'handler.exception.error_occurred', name:).light_red
  puts I18n.t(:'handler.exception.create_an_issue', url: issue_url).light_red
  puts I18n.t(:'handler.exception.send_email_instead', email: dev_email).light_red
  error_info = "Exception occurred: #{exception.class}. Message: #{exception.message}. Backtrace:"
  puts "#{error_info}\n#{exception.backtrace.join("\n")}"
  puts I18n.t(:'handler.exception.skipping_step').yellow
end
