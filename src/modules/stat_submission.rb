# frozen_string_literal: true

def submit_stats(stat_tracker)
  uri = URI('https://checksch.de/hook/disenchanter.php')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.request(build_stat_request(stat_tracker))
rescue StandardError => e
  handle_exception(e, 'stat submission')
end

def build_stat_request(stat_tracker)
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
    "Would you like to contribute your (anonymous) stats to the global stats?\n".light_cyan +
      "#{gather_stats(stat_tracker)}[y|n]: ",
    ans_yn, ans_yn_d,
    ''
  )
    submit_stats(stat_tracker)
    puts 'Thank you very much!'.light_green
  end
end

def gather_stats(stat_tracker)
  out = "Your stats:\n".light_blue
  stats = ['Actions', 'Disenchanted', 'Opened', 'Crafted', 'Redeemed', 'Blue Essence', 'Orange Essence']

  out + stats.map { |stat| wrap_stat_line(stat, stat_tracker.send(stat.downcase.gsub(' ', '_'))) }.join
end

def wrap_stat_line(name, value)
  strlen = 15
  numlen = 7
  out = pad(name, strlen)
  out += pad(value.to_s, numlen, right: false).light_white
  "#{out}\n"
end
