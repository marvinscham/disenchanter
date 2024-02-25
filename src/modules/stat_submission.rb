# frozen_string_literal: true

def submit_stats(stat_tracker)
  uri = URI('https://checksch.de/hook/disenchanter.php')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.request(build_stat_request(uri, stat_tracker))
rescue StandardError => e
  handle_exception(e, 'stat submission')
end

def build_stat_request(uri, stat_tracker)
  req = Net::HTTP::Post.new(uri, 'Content-Type': 'application/json')
  req.body = { a: stat_tracker.actions,
               d: stat_tracker.disenchanted,
               o: stat_tracker.opened,
               c: stat_tracker.crafted,
               r: stat_tracker.redeemed,
               be: stat_tracker.blue_essence,
               oe: stat_tracker.orange_essence }.to_json

  req
end

def handle_stat_submission(stat_tracker)
  return if stat_tracker.actions.zero?

  if ans_y.include? user_input_check(
    "#{I18n.t(:'handler.stat_submission.ask_contribute')}\n".light_cyan +
      "#{gather_stats(stat_tracker)}#{I18n.t(:'handler.stat_submission.ask_submit')}",
    ans_yn, ans_yn_d,
    ''
  )
    submit_stats(stat_tracker)
    puts I18n.t(:'handler.stat_submission.thanks').light_green
  end
end

def gather_stats(stat_tracker)
  out = "Your stats:\n".light_blue
  stats = {
    I18n.t(:'common.actions') => stat_tracker.actions,
    I18n.t(:'common.disenchanted') => stat_tracker.disenchanted,
    I18n.t(:'common.opened') => stat_tracker.opened,
    I18n.t(:'common.crafted') => stat_tracker.crafted,
    I18n.t(:'common.redeemed') => stat_tracker.redeemed,
    I18n.t(:'loot.blue_essence') => stat_tracker.blue_essence,
    I18n.t(:'loot.orange_essence') => stat_tracker.orange_essence
  }

  out + stats.map { |stat, value| wrap_stat_line(stat, value) }.join
end

def wrap_stat_line(name, value)
  strlen = 15
  numlen = 7
  out = pad(name, strlen)
  out += pad(value.to_s, numlen, right: false).light_white
  "#{out}\n"
end
