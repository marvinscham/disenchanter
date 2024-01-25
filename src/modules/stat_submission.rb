# frozen_string_literal: true

def submit_stats(a, d, o, c, r, be, oe)
  begin
    uri = URI('https://checksch.de/hook/disenchanter.php')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(uri, "Content-Type": 'application/json')

    req.body = { a: a, d: d, o: o, c: c, r: r, be: be, oe: oe }.to_json
    http.request(req)
  rescue => exception
    handle_exception(exception, 'stat submission')
  end
end

def handle_stat_submission
  if $actions > 0
    strlen = 15
    numlen = 7
    stats_string = "Your stats:\n".light_blue
    stats_string +=
      pad('Actions', strlen) + pad($actions.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad('Disenchanted', strlen) +
        pad($s_disenchanted.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad('Opened', strlen) + pad($s_opened.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad('Crafted', strlen) + pad($s_crafted.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad('Redeemed', strlen) +
        pad($s_redeemed.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad('Blue Essence', strlen) +
        pad($s_blue_essence.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad('Orange Essence', strlen) +
        pad($s_orange_essence.to_s, numlen, false).light_white + "\n"

    if ($ans_y).include? user_input_check(
      "Would you like to contribute your (anonymous) stats to the global stats?\n".light_cyan +
        stats_string + '[y|n]: ',
      $ans_yn,
      $ans_yn_d,
      ''
    )
      submit_stats(
        $actions,
        $s_disenchanted,
        $s_opened,
        $s_crafted,
        $s_redeemed,
        $s_blue_essence,
        $s_orange_essence
      )
      puts 'Thank you very much!'.light_green
    end
  end
end
