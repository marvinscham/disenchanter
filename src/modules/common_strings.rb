# frozen_string_literal: true

def exit_string
  'Press Enter to exit.'.cyan
end

def separator
  '____________________________________________________________'.light_black
end

def ans_yn
  %w[y yes n no]
end

def ans_y
  %w[y yes]
end

def ans_n
  %w[n no]
end

def ans_yn_d
  '[y|n]'
end

def pad(str, len, right: true)
  format("%#{right ? '-' : ''}#{len}s", str)
end
