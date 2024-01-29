# frozen_string_literal: true

def handle_champions_exceptions(loot_shards)
  exclusions_str = ''
  exclusions_done = false
  exclusions_done_more = ''
  exclusions_arr = []
  until exclusions_done
    if ans_y.include? user_input_check(
      "Would you like to add #{exclusions_done_more}exclusions?",
      ans_yn,
      ans_yn_d
    )
      exclusions_str +=
        ',' +
        ask(
          'Okay, which champions? '.light_cyan +
            '(case-sensitive, comma-separated)'.light_white +
            ': '.light_cyan
        )

      exclusions_done_more = 'more '

      exclusions_arr = exclusions_str.split(/\s*,\s*/)
      exclusions_matched =
        loot_shards.select { |l| exclusions_arr.include? l['itemDesc'] }
      print 'Exclusions recognized: '.green
      exclusions_matched.each { |e| print e['itemDesc'].light_white + ' ' }
      puts
    else
      exclusions_done = true
    end
  end
  loot_shards.reject { |l| exclusions_arr.include? l['itemDesc'] }
rescue StandardError => e
  handle_exception(e, 'Champion Shard Exceptions')
end
