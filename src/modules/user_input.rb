# frozen_string_literal: true

def ask(question)
  print(question)
  question = gets
  question.chomp
end

def user_input_check(question, answers, answer_display, color_preset = 'default')
  input = ''

  case color_preset
  when 'confirm'
    question =
      "CONFIRM: #{question} ".light_magenta + answer_display.to_s.light_white + ': '.light_magenta
  when 'default'
    question =
      question.light_cyan + "#{answer_display}: ".light_white
  end

  until answers.include? input
    input = ask question
    puts 'Invalid answer, options: '.light_red + answer_display.to_s.light_white unless answers.include? input
  end

  input
end
