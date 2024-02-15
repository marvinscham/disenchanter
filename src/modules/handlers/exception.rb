# frozen_string_literal: true

def handle_exception(exception, name)
  puts "An error occurred while handling #{name}.".light_red
  puts 'Please take a screenshot and create an issue at https://github.com/marvinscham/disenchanter/issues/new'.light_red
  puts "If you don't have a GitHub account, send it to dev@marvinscham.de".light_red
  puts "Exception Occurred #{exception.class}. Message: #{exception.message}. Backtrace:  \n #{exception.backtrace.join("\n")}"
  puts 'Skipping this step...'.yellow
end
