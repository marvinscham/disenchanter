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
    question = "#{I18n.t(:'common.confirm_banner')}: #{question} ".light_magenta +
               answer_display.to_s.light_white + ': '.light_magenta
  when 'dry'
    question += " #{answer_display} (#{I18n.t(:'common.dry_run_banner')}): ".light_red
  else
    question += " #{answer_display}: ".light_white
  end

  until answers.include? input
    input = ask question
    unless answers.include? input
      puts "#{I18n.t(:'common.invalid_answer')}: ".light_red + answer_display.to_s.light_white
    end
  end

  input
end
