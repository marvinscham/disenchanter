# frozen_string_literal: true

require_relative 'champions/collection'
require_relative 'champions/exceptions'
require_relative 'champions/mastery'
require_relative 'champions/owned'
require_relative 'champions/tokens'

def handle_champions
  begin
    player_loot = get_player_loot
    loot_shards = player_loot.select { |l| l['type'] == 'CHAMPION_RENTAL' }

    loot_perms = player_loot.select { |l| l['type'] == 'CHAMPION' }
    if count_loot_items(loot_perms) > 0
      if ($ans_y).include? user_input_check(
        'Should we include champion permanents in this process?',
        $ans_yn,
        $ans_yn_d
      )
        loot_shards =
          player_loot.select do |l|
            l['type'] == 'CHAMPION_RENTAL' || l['type'] == 'CHAMPION'
          end
      end
    end

    if count_loot_items(loot_shards) > 0
      puts "Found #{count_loot_items(loot_shards)} champion shards.".light_blue

      loot_shards.each do |s|
        s['count_keep'] = 0
        s['disenchant_note'] = ''
      end
      loot_shards_not_owned =
        loot_shards.select { |s| s['redeemableStatus'] != 'ALREADY_OWNED' }

      if loot_shards_not_owned.length > 0
        if ($ans_y).include? user_input_check(
          "Keep a shard for champions you don't own yet?",
          $ans_yn,
          $ans_yn_d
        )
          loot_shards = handle_champions_owned(loot_shards)
        end
      else
        puts "Found no shards of champions you don't own yet.".light_blue
      end

      disenchant_modes = {
        '1' => 'Disenchant all champion shards',
        '2' => 'Keep enough (1/2) shards for champions you own mastery 6/7 tokens for',
        '3' => 'Keep enough (1/2) shards to fully master champions at least at mastery level x (select from 1 to 6)',
        '4' => 'Keep enough (1/2) shards to fully master all champions (only disenchant shards that have no possible use)',
        '5' => 'Keep one shard of each champion regardless of mastery',
        'x' => 'Cancel',
      }

      modes_string = ''
      disenchant_modes.each do |k, v|
        modes_string += "[#{k}] ".light_white
        modes_string += "#{v}\n".light_cyan
      end

      disenchant_shards_mode =
        user_input_check(
          "Okay, which option would you like to go by?\n" + modes_string +
            'Option: ',
          disenchant_modes.keys,
          '[1|2|3|4|5|x]',
          ''
        )
      unless disenchant_shards_mode == 'x'
        case disenchant_shards_mode
        when '1'
          # no filtering needed -> done
        when '2'
          loot_shards = handle_champions_tokens(player_loot, loot_shards)
        when '3'
          loot_shards = handle_champions_mastery(loot_shards)
        when '4'
          loot_shards = handle_champions_mastery(loot_shards, true)
        when '5'
          loot_shards = handle_champions_collection(loot_shards)
        end

        loot_shards = loot_shards.select { |l| l['count'] > 0 }
        loot_shards =
          loot_shards.sort_by { |l| [l['disenchant_note'], l['itemDesc']] }

        if count_loot_items(loot_shards) > 0
          puts "We'd disenchant #{count_loot_items(loot_shards)} champion shards using the option you chose:".light_blue
          loot_shards.each do |l|
            loot_value = l['disenchantValue'] * l['count']
            print pad("#{l['count']}x ", 5, false).light_black
            print pad("#{l['itemDesc']}", 15).light_white
            print ' @ '.light_black
            print pad("#{loot_value} BE", 8, false).light_black
            if l['count_keep'] > 0
              puts " keeping #{l['count_keep']}".green
            elsif l['disenchant_note'].length > 0
              puts " #{l['disenchant_note']}"
            else
              puts
            end
          end

          loot_shards = handle_champions_exceptions(loot_shards)

          total_be_value = 0
          loot_shards.each do |l|
            total_be_value += l['disenchantValue'] * l['count']
          end

          if count_loot_items(loot_shards) > 0
            if $ans_y.include? user_input_check(
              "Disenchant #{count_loot_items(loot_shards)} champion shards for #{total_be_value} Blue Essence?",
              $ans_yn,
              $ans_yn_d,
              'confirm'
            )
              $s_blue_essence += total_be_value
              $s_disenchanted += count_loot_items(loot_shards)
              threads =
                loot_shards.map do |s|
                  Thread.new do
                    post_recipe(
                      'CHAMPION_RENTAL_disenchant',
                      s['lootId'],
                      s['count']
                    )
                  end
                end
              threads.each(&:join)
              puts 'Done!'.green
            end
          else
            puts 'All remaining champions have been excluded, skipping...'.yellow
          end
        else
          puts "Job's already done: no champion shards left matching your selection.".green
        end
      else
        puts 'Champion shard disenchanting canceled.'.yellow
      end
    else
      puts 'Found no champion shards to disenchant.'.yellow
    end
  rescue => exception
    handle_exception(exception, 'Champion Shards')
  end
end
