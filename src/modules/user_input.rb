# frozen_string_literal: true

def ask(q)
  print(q)
  q = gets
  q.chomp
end

def user_input_check(question, answers, answerdisplay, color_preset = 'default')
  input = ''

  case color_preset
  when 'confirm'
    question =
      "CONFIRM: #{question} ".light_magenta + "#{answerdisplay}".light_white +
      ': '.light_magenta
  when 'default'
    question =
      "#{question} ".light_cyan + "#{answerdisplay}".light_white +
      ': '.light_cyan
  end

  until answers.include? input
    input = ask question
    unless answers.include? input
      puts 'Invalid answer, options: '.light_red +
           "#{answerdisplay}".light_white
    end
  end

  input
end
