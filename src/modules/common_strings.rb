# frozen_string_literal: true

require 'colorize'

def exit_string
  I18n.t(:'common.press_enter_to_exit').cyan
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
  full_width_str_len = str.scan(/\p{Han}/).size
  full_width_str_len += str.scan(/\p{Symbol}/).size
  format("%#{right ? '-' : ''}#{len - full_width_str_len}s", str)
end

unless String.method_defined?(:light_yellow)
  # Type hints!
  class String
    def light_yellow = self
    def light_blue = self
    def light_green = self
    def light_white = self
    def light_black = self
    def light_red = self
    def light_magenta = self
    def light_cyan = self
  end
end
