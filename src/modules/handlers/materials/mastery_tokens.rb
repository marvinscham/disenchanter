# frozen_string_literal: true

def handle_mastery_tokens
  begin
    player_loot = get_player_loot
    loot_shards = player_loot.select { |l| l['type'] == 'CHAMPION_RENTAL' }
    loot_perms = player_loot.select { |l| l['type'] == 'CHAMPION' }

    recipes6 = get_recipes_for_item('CHAMPION_TOKEN_6-1')
    recipes7 = get_recipes_for_item('CHAMPION_TOKEN_7-1')
    recipe6_cost =
      recipes6.select do |r|
        r['recipeName'] == 'CHAMPION_TOKEN_6_redeem_withessence'
      end
    recipe6_cost = recipe6_cost[0]['slots'][1]['quantity']
    recipe7_cost =
      recipes7.select do |r|
        r['recipeName'] == 'CHAMPION_TOKEN_7_redeem_withessence'
      end
    recipe7_cost = recipe7_cost[0]['slots'][1]['quantity']

    loot_overall_tokens =
      player_loot.select do |l|
        (l['lootName'] == 'CHAMPION_TOKEN_6') ||
          (l['lootName'] == 'CHAMPION_TOKEN_7')
      end

    puts "Found #{count_loot_items(loot_overall_tokens)} Mastery Tokens.".light_blue

    loot_mastery_tokens =
      player_loot.select do |l|
        (l['lootName'] == 'CHAMPION_TOKEN_6' && l['count'] == 2) ||
          (l['lootName'] == 'CHAMPION_TOKEN_7' && l['count'] == 3)
      end

    if loot_mastery_tokens.count > 0
      loot_mastery_tokens =
        loot_mastery_tokens.sort_by { |l| [l['lootName'], l['itemDesc']] }
      puts "We could upgrade the following champions:\n".light_blue
      needed_shards = 0
      needed_perms = 0
      needed_essence = 0

      loot_mastery_tokens.each do |t|
        ref_shard =
          loot_shards.select { |l| t['refId'] == l['storeItemId'].to_s }
        ref_perm =
          loot_shards.select { |l| t['refId'] == l['storeItemId'].to_s }

        print pad(t['itemDesc'], 15, false).light_white
        print ' to Mastery Level '.light_black
        print "#{(t['lootName'])[-1]}".light_white
        print ' using '.light_black
        if !ref_shard.empty? && ref_shard[0]['count'] > 0
          print 'a champion shard.'.green
          needed_shards += 1
          t['upgrade_type'] = 'shard'
        elsif !ref_perm.empty? && ref_shard[0]['count'] > 0
          print 'a champion permanent.'.green
          needed_perms += 1
          t['upgrade_type'] = 'permanent'
        else
          recipe_cost = (t['lootName'])[-1] == '6' ? recipe6_cost : recipe7_cost
          print "#{recipe_cost} Blue Essence.".yellow
          needed_essence += recipe_cost
          t['upgrade_type'] = 'essence'
        end
        puts
      end
      puts

      owned_essence =
        player_loot.select { |l| l['lootId'] == 'CURRENCY_champion' }
      owned_essence = owned_essence[0]['count']
      if (owned_essence > needed_essence)
        question_string =
          "Upgrade #{loot_mastery_tokens.count} champions using "
        question_string += "#{needed_shards} Shards, " if needed_shards > 0
        question_string += "#{needed_perms} Permanents, " if needed_perms > 0
        question_string +=
          "#{needed_essence} Blue Essence, " if needed_essence > 0
        question_string = question_string.delete_suffix(', ')
        question_string += '?'

        if $ans_y.include? user_input_check(
          question_string,
          $ans_yn,
          $ans_yn_d,
          'confirm'
        )
          loot_mastery_tokens.each do |t|
            $s_redeemed += 1
            target_level = (t['lootName'])[-1]
            case t['upgrade_type']
            when 'shard'
              post_recipe(
                "CHAMPION_TOKEN_#{target_level}_redeem_withshard",
                [t['lootId'], "CHAMPION_RENTAL_#{t['refId']}"],
                1
              )
            when 'permanent'
              post_recipe(
                "CHAMPION_TOKEN_#{target_level}_redeem_withpermanent",
                [t['lootId'], "CHAMPION_#{t['refId']}"],
                1
              )
            when 'essence'
              post_recipe(
                "CHAMPION_TOKEN_#{target_level}_redeem_withessence",
                [t['lootId'], 'CURRENCY_champion'],
                1
              )
            end
          end
        end
      else
        puts "You're missing #{needed_essence - owned_essence} Blue Essence needed to proceed. Skipping...".yellow
      end
    else
      puts 'Found no upgradable set of Mastery Tokens.'.yellow
    end
  rescue => exception
    handle_exception(exception, 'token upgrades')
  end
end