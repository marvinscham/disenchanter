# frozen_string_literal: true

# Allows adding exceptions to a previously made Champion Shard disenchantment selection
# @param loot_shards Loot array, champion shards and permanents only
def handle_champions_exclusions(loot_shards)
  exclusions_str = ''
  exclusions_arr = []
  exclusions_done = false

  until exclusions_done
    if ans_y.include? user_input_check(
      'Would you like to add exclusions?',
      ans_yn,
      ans_yn_d
    )
      exclusions_arr += handle_champion_exclusion(loot_shards, exclusions_str)
    else
      exclusions_done = true
    end
  end

  loot_shards.reject { |l| exclusions_arr.include? l['itemDesc'] }
rescue StandardError => e
  handle_exception(e, 'Champion Shard Exceptions')
end

def handle_champion_exclusion(loot_shards, exclusions_str)
  exclusions_str += ','
  exclusions_str += ask(
    'Okay, which champions? '.light_cyan +
      '(case-sensitive, comma-separated)'.light_white +
      ': '.light_cyan
  )

  exclusions_arr = exclusions_str.split(/\s*,\s*/)
  exclusions_matched = loot_shards.select { |l| exclusions_arr.include? l['itemDesc'] }

  print 'Exclusions recognized: '.green
  exclusions_matched.each { |e| print "#{e['itemDesc'].light_white} " }
  puts

  exclusions_arr
end
