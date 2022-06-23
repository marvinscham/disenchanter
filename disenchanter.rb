#!/usr/bin/env ruby
# frozen_string_literal: true

require "net/https"
require "base64"
require "json"
require "colorize"

def run
  current_version = "v1.2.3"

  sep =
    "____________________________________________________________".light_black

  puts "Hi! :)".light_green
  puts "Running Disenchanter #{current_version}".light_white
  check_update(current_version)
  puts "You can exit this script at any point by pressing CTRL + C.".light_blue
  puts sep

  set_globals

  summoner = get_current_summoner
  if summoner["displayName"].nil? || summoner["displayName"].empty?
    puts "Could not grab summoner info. Try restarting your League Client.".light_red
    ask "Press Enter to exit.".cyan
    exit 1
  end
  puts "You're logged in as #{summoner["displayName"]}.".light_blue
  puts sep

  handle_event_tokens
  puts sep

  handle_mythic_essence
  puts sep

  handle_key_fragments
  puts sep

  handle_capsules
  puts sep

  handle_emotes
  puts sep

  handle_champion_shards
  puts sep

  puts "That's it!".light_green
  puts "You can find the global usage stats of Disenchanter at https://github.com/marvinscham/disenchanter/wiki/Stats".light_blue
  if $actions > 0
    puts "We saved you about #{$actions * 3} seconds of waiting for animations to finish.".light_green
    puts sep

    if ($ans_yes).include? user_input_check(
                    "Would you like to contribute your anonymous results (number of shards disenchanted etc.) to the global stats?\n",
                    $ans_yesno,
                    $ans_yesno_disp
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
      puts "Thank you very much!".light_green
    end
  end
  puts "See you next time :)".light_green
  ask "Press Enter to exit.".cyan
end

def ask(q)
  print(q)
  q = gets
  q.chomp
end

def pad(str, len, right = true)
  "%#{right ? "-" : ""}#{len}s" % str
end

def set_globals
  begin
    $port, $token = read_lockfile
  rescue StandardError
    puts "Could not grab session!".light_red
    puts "Make sure the script is in your League Client folder and that your Client is running.".light_red
    ask "Press Enter to exit.".cyan
    exit 1
  end
  $host = "https://127.0.0.1:#{$port}"

  $actions = 0
  $s_disenchanted = 0
  $s_opened = 0
  $s_crafted = 0
  $s_redeemed = 0
  $s_blue_essence = 0
  $s_orange_essence = 0

  $ans_yesno = %w[y yes n no true false]
  $ans_yes = %w[y yes true]
  $ans_no = %w[n no false]
  $ans_yesno_disp = "[y|n]"
end

def read_lockfile
  contents = File.read("lockfile")
  _leagueclient, _unk_port, port, password = contents.split(":")
  token = Base64.encode64("riot:#{password.chomp}")

  [port, token]
end

def create_client
  Net::HTTP.start(
    "127.0.0.1",
    $port,
    use_ssl: true,
    verify_mode: OpenSSL::SSL::VERIFY_NONE
  ) { |http| yield(http) }
end

def req_set_headers(req)
  req["Content-Type"] = "application/json"
  req["Authorization"] = "Basic #{$token.chomp}"
end

def check_update(version)
  uri =
    URI("https://api.github.com/repos/marvinscham/disenchanter/releases/latest")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Get.new(uri, "Content-Type": "application/json")
  res = http.request req
  ans = JSON.parse(res.body)

  if (ans["tag_name"] != version)
    puts "New version #{ans["tag_name"]} available at https://github.com/marvinscham/disenchanter/releases/latest".light_red
  else
    puts "You're up to date!".green
  end
end

def request_get(path)
  create_client do |http|
    uri = URI("#{$host}/#{path}")
    req = Net::HTTP::Get.new(uri)
    req_set_headers(req)
    res = http.request req
    JSON.parse(res.body)
  end
end

def request_post(path, body)
  create_client do |http|
    uri = URI("#{$host}/#{path}")
    req = Net::HTTP::Post.new(uri, "Content-Type": "application/json")
    req.body = body
    req_set_headers(req)
    http.request req
  end
end

def get_current_summoner()
  request_get("lol-summoner/v1/current-summoner")
end

def get_player_loot()
  request_get("lol-loot/v1/player-loot")
end

def get_champion_mastery(summoner_id)
  request_get("lol-collections/v1/inventories/#{summoner_id}/champion-mastery")
end

def get_loot_info(loot_id)
  request_get("lol-loot/v1/player-loot/#{loot_id}")
end

def get_recipes_for_item(loot_id)
  request_get("lol-loot/v1/recipes/initial-item/#{loot_id}")
end

def post_recipe(recipe, loot_id, repeat)
  $actions += repeat
  request_post(
    "lol-loot/v1/recipes/#{recipe}/craft?repeat=#{repeat}",
    "[\"#{loot_id}\"]"
  )
end

def user_input_check(question, answers, answerdisplay, confirm = false)
  input = ""

  until (answers).include? input
    if confirm
      question =
        "CONFIRM: #{question} ".light_magenta + "#{answerdisplay}".light_white +
          ": ".light_magenta
    else
      question =
        "#{question} ".light_cyan + "#{answerdisplay}".light_white +
          ": ".light_cyan
    end

    input = ask question
    unless (answers).include? input
      puts "Invalid answer, options: ".light_red +
             "#{answerdisplay}".light_white
    end
  end

  input
end

def count_loot_items(loot_items)
  count = 0
  loot_items.each { |loot| count += loot["count"] }
  count
end

def get_chest_name(loot_id)
  chest_info = get_loot_info(loot_id)
  return chest_info["localizedName"] if !chest_info["localizedName"].empty?

  catalogue = {
    "CHEST_128" => "Champion Capsule",
    "CHEST_129" => "Glorious Champion Capsule",
    "CHEST_210" => "Honor Level 4 Orb"
  }

  return catalogue[loot_id] if catalogue.key?(loot_id)

  return loot_id
end

def handle_exception(exception, name)
  puts "An error occurred while handling #{name}.".light_red
  puts "Please take a screenshot and create an issue at https://github.com/marvinscham/disenchanter/issues/new".light_red
  puts "If you don't have a GitHub account, send it to dev@marvinscham.de".light_red
  puts exception
  puts "Skipping this step...".light_black
end

def handle_event_tokens
  begin
    player_loot = get_player_loot

    loot_event_token =
      player_loot.select do |l|
        l["type"] == "MATERIAL" && l["displayCategories"] == "CHEST" &&
          l["lootId"].start_with?("MATERIAL_") &&
          !l["lootId"].start_with?("MATERIAL_key")
      end
    loot_event_token = loot_event_token[0]

    if !loot_event_token.nil? && loot_event_token["count"] > 0
      puts "Found Event Tokens: #{loot_event_token["count"]}x #{loot_event_token["localizedName"]}".light_blue
      token_recipes = get_recipes_for_item(loot_event_token["lootId"])

      craft_tokens_type_names = ["Blue Essence", "Random Emotes"]

      if ($ans_yes).include? user_input_check(
                      "Craft #{loot_event_token["localizedName"]}s to #{craft_tokens_type_names[0]} or #{craft_tokens_type_names[1]}?",
                      $ans_yesno,
                      $ans_yesno_disp
                    )
        craft_tokens_type =
          user_input_check(
            "Okay, what would you like to craft?\n" +
              "[1] #{craft_tokens_type_names[0]}\n" +
              "[2] #{craft_tokens_type_names[1]}\n" + "[x] Cancel\n",
            %w[1 2 x],
            "[1|2|x]"
          )

        unless craft_tokens_type == "x"
          # CHEST_187 = Random Emote
          # CHEST_241 = Random Champion Shard
          # CURRENCY_champion = Blue Essence
          if %w[1 essence].include? craft_tokens_type
            recipe_targets = %w[CHEST_241 CURRENCY_champion]
          elsif %w[2 emotes].include? craft_tokens_type
            recipe_targets = %w[CHEST_187]
          end

          token_recipes =
            token_recipes.select do |r|
              recipe_targets.include? r["outputs"][0]["lootName"]
            end
          token_recipes.sort_by { |r| r["slots"][0]["quantity"] }.reverse!

          token_recipes.each do |r|
            puts "Recipe found: #{r["contextMenuText"]} for #{r["slots"][0]["quantity"]} Tokens".light_black
          end

          craft_tokens_amount =
            user_input_check(
              "Alright, how many Event Tokens should we use to craft #{craft_tokens_type_names[craft_tokens_type.to_i - 1]}?",
              (1..loot_event_token["count"].to_i)
                .to_a
                .append("all")
                .map! { |n| n.to_s },
              "[1..#{loot_event_token["count"]}|all]"
            )

          if craft_tokens_amount == "all"
            craft_tokens_amount = loot_event_token["count"]
          end
          craft_tokens_amount = craft_tokens_amount.to_i

          total_could_craft = 0

          token_recipes.each do |r|
            r["could_craft"] = (
              craft_tokens_amount / r["slots"][0]["quantity"]
            ).floor
            total_could_craft += r["could_craft"]
            craft_tokens_amount -=
              (craft_tokens_amount / r["slots"][0]["quantity"]).floor *
                r["slots"][0]["quantity"]
            if r["could_craft"] > 0
              puts "We could craft #{r["could_craft"]}x #{r["contextMenuText"]} for #{r["slots"][0]["quantity"]} Tokens each.".light_green
            end
          end

          token_recipes = token_recipes.select { |r| r["could_craft"] > 0 }

          if total_could_craft > 0
            if ($ans_yes).include? user_input_check(
                            "Commit to forging?",
                            $ans_yesno,
                            $ans_yesno_disp,
                            true
                          )
              token_recipes.each do |r|
                if craft_tokens_type == "1"
                  $s_blue_essence +=
                    r["outputs"][0]["quantity"] * r["could_craft"]
                end
                $s_crafted += r["could_craft"]
              end

              threads =
                token_recipes.map do |r|
                  Thread.new do
                    post_recipe(
                      r["recipeName"],
                      loot_event_token["lootId"],
                      r["could_craft"]
                    )
                  end
                end
              threads.each(&:join)
              puts "Done!".green
            end
          else
            puts "Can't afford any recipe, skipping.".yellow
          end
        else
          puts "Token crafting canceled.".yellow
        end
      end
    else
      puts "Found no Event Tokens.".light_black
    end
  rescue => exception
    handle_exception(exception, "Event Tokens")
  end
end

def handle_mythic_essence
  begin
    player_loot = get_player_loot
    mythic_loot_id = "CURRENCY_mythic"

    loot_essence = player_loot.select { |l| l["lootId"] == mythic_loot_id }
    loot_essence = loot_essence[0]
    if !loot_essence.nil? && loot_essence["count"] > 0
      puts "Found #{loot_essence["count"]} Mythic Essence.".light_blue
      if ($ans_yes).include? user_input_check(
                      "Craft Mythic Essence to Skin Shards, Blue Essence or Orange Essence?",
                      $ans_yesno,
                      $ans_yesno_disp
                    )
        craft_mythic_type_names = [
          "Blue Essence",
          "Orange Essence",
          "Random Skin Shards"
        ]

        craft_mythic_type =
          user_input_check(
            "Okay, what would you like to craft?\n" +
              "[1] #{craft_mythic_type_names[0]}\n" +
              "[2] #{craft_mythic_type_names[1]}\n" +
              "[3] #{craft_mythic_type_names[2]}\n" + "[x] Cancel\n",
            %w[1 2 3 x],
            "[1|2|3|x]"
          )

        unless craft_mythic_type == "x"
          case craft_mythic_type
          # Blue Essence, Orange Essence, Random Skin Shard
          when "1"
            recipe_target = "CURRENCY_champion"
          when "2"
            recipe_target = "CURRENCY_cosmetic"
          when "3"
            recipe_target = "CHEST_291"
          end

          recipes = get_recipes_for_item(mythic_loot_id)
          recipes =
            recipes.select { |r| r["outputs"][0]["lootName"] == recipe_target }
          unless recipes.length == 0
            recipe = recipes[0]

            puts "Recipe found: #{recipe["contextMenuText"]} for #{recipe["slots"][0]["quantity"]} Mythic Essence".light_blue

            craft_mythic_amount =
              user_input_check(
                "Alright, how much Mythic Essence should we use to craft #{craft_mythic_type_names[craft_mythic_type.to_i - 1]}?",
                (1..loot_essence["count"].to_i)
                  .to_a
                  .append("all")
                  .map! { |n| n.to_s },
                "[1..#{loot_essence["count"]}|all]"
              )

            if craft_mythic_amount == "all"
              craft_mythic_amount = loot_essence["count"]
            end
            craft_mythic_amount = craft_mythic_amount.to_i

            could_craft =
              (craft_mythic_amount / recipe["slots"][0]["quantity"]).floor
            unless could_craft < 1
              if ($ans_yes).include? user_input_check(
                              "Craft #{could_craft * recipe["outputs"][0]["quantity"]} " +
                                "#{craft_mythic_type_names[craft_mythic_type.to_i - 1]} from " +
                                "#{(craft_mythic_amount / recipe["slots"][0]["quantity"]).floor * recipe["slots"][0]["quantity"]} Mythic Essence?",
                              $ans_yesno,
                              $ans_yesno_disp,
                              true
                            )
                case craft_mythic_type
                when "1"
                  $s_blue_essence +=
                    could_craft * recipe["outputs"][0]["quantity"]
                when "2"
                  $s_orange_essence +=
                    could_craft * recipe["outputs"][0]["quantity"]
                end
                $s_crafted += could_craft

                post_recipe(
                  recipe["recipeName"],
                  mythic_loot_id,
                  (craft_mythic_amount / recipe["slots"][0]["quantity"]).floor
                )
                puts "Done!".green
              end
            else
              puts "Not enough Mythic Essence for that recipe.".yellow
            end
          else
            puts "Recipes for #{craft_mythic_type_names[craft_mythic_type.to_i - 1]} seem to be unavailable.".yellow
          end
        else
          puts "Mythic crafting canceled.".yellow
        end
      end
    else
      puts "Found no Mythic Essence to use.".light_black
    end
  rescue => exception
    handle_exception(exception, "Mythic Essence")
  end
end

def handle_key_fragments
  begin
    player_loot = get_player_loot

    loot_keys =
      player_loot.select { |l| l["lootId"] == "MATERIAL_key_fragment" }
    if count_loot_items(loot_keys) >= 3
      puts "Found #{count_loot_items(loot_keys)} key fragments.".light_blue
      if ($ans_yes).include? user_input_check(
                      "Craft #{(count_loot_items(loot_keys) / 3).floor} keys from #{count_loot_items(loot_keys)} key fragments?",
                      $ans_yesno,
                      $ans_yesno_disp,
                      true
                    )
        $s_crafted += (count_loot_items(loot_keys) / 3).floor
        post_recipe(
          "MATERIAL_key_fragment_forge",
          "MATERIAL_key_fragment",
          (count_loot_items(loot_keys) / 3).floor
        )
        puts "Done!".green
      end
    else
      puts "Found less than 3 key fragments.".light_black
    end
  rescue => exception
    handle_exception(exception, "Key Fragments")
  end
end

def handle_capsules
  begin
    player_loot = get_player_loot

    loot_capsules =
      player_loot.select { |l| l["lootName"].start_with?("CHEST_") }
    loot_capsules.each do |c|
      recipes = get_recipes_for_item(c["lootId"])
      if recipes[0]["slots"].length > 1 || !recipes[0]["type"] == "OPEN"
        c["needs_key"] = true
      else
        c["needs_key"] = false
      end
    end
    loot_capsules = loot_capsules.select { |c| c["needs_key"] == false }

    if count_loot_items(loot_capsules) > 0
      puts "Found #{count_loot_items(loot_capsules)} capsules:".light_blue
      loot_capsules.each do |c|
        puts "#{c["count"]}x ".light_black +
               "#{get_chest_name(c["lootId"])}".light_white
      end

      if ($ans_yes).include? user_input_check(
                      "Open #{count_loot_items(loot_capsules)} (keyless) capsules?",
                      $ans_yesno,
                      $ans_yesno_disp,
                      true
                    )
        $s_opened += count_loot_items(loot_capsules)
        threads =
          loot_capsules.map do |c|
            Thread.new do
              post_recipe(c["lootId"] + "_OPEN", c["lootId"], c["count"])
            end
          end
        threads.each(&:join)
        puts "Done!".green
      end
    else
      puts "Found no keyless capsules to open.".light_black
    end
  rescue => exception
    handle_exception(exception, "Capsules")
  end
end

def handle_emotes
  begin
    player_loot = get_player_loot

    loot_emotes =
      player_loot.select do |l|
        l["type"] == "EMOTE" && l["redeemableStatus"] == "ALREADY_OWNED"
      end
    if count_loot_items(loot_emotes) > 0
      total_oe_value = 0
      loot_emotes.each { |e| total_oe_value += e["disenchantValue"] }
      if ($ans_yes).include? user_input_check(
                      "Disenchant #{count_loot_items(loot_emotes)} (already owned) emotes for #{total_oe_value} Orange Essence?",
                      $ans_yesno,
                      $ans_yesno_disp,
                      true
                    )
        $s_disenchanted += count_loot_items(loot_emotes)
        $s_orange_essence += total_oe_value
        threads =
          loot_emotes.map do |e|
            Thread.new do
              post_recipe("EMOTE_disenchant", e["lootId"], e["count"])
            end
          end
        threads.each(&:join)
        puts "Done!".green
      end
    else
      puts "Found no owned emotes to disenchant.".light_black
    end
  rescue => exception
    handle_exception(exception, "Emotes")
  end
end

def handle_champion_shards
  begin
    player_loot = get_player_loot

    loot_shards = player_loot.select { |l| l["type"] == "CHAMPION_RENTAL" }
    if count_loot_items(loot_shards) > 0
      puts "Found #{count_loot_items(loot_shards)} champion shards.".light_blue

      if ($ans_yes).include? user_input_check(
                      "Disenchant unneeded champion shards?",
                      $ans_yesno,
                      $ans_yesno_disp
                    )
        loot_shards.each do |s|
          s["count_keep"] = 0
          s["disenchant_note"] = ""
        end
        loot_shards_not_owned =
          loot_shards.select { |s| !s["redeemableStatus"] == "ALREADY_OWNED" }

        if loot_shards_not_owned.length > 0
          if ($ans_yes).include? user_input_check(
                          "Keep a shard for champions you don't own yet?",
                          $ans_yesno,
                          $ans_yesno_disp
                        )
            loot_shards = handle_champion_shards_owned(loot_shards)
          end
        end

        disenchant_shards_mode =
          user_input_check(
            "Okay, which mode would you like to go by?\n" +
              "[1] Disenchant all champion shards\n" +
              "[2] Keep enough (1/2) shards for champions you own mastery 6/7 tokens for\n" +
              "[3] Keep enough (1/2) shards to fully master champions at least at mastery level x (select from 1 to 6)\n" +
              "[4] Keep enough (1/2) shards to fully master all champions (only disenchant shards that have no possible use)\n" +
              "[x] Cancel\n",
            %w[1 2 3 4 x],
            "[1|2|3|4|x]"
          )
        unless disenchant_shards_mode == "x"
          case disenchant_shards_mode
          when "1"
            # done
          when "2"
            loot_shards =
              handle_champion_shards_tokens(player_loot, loot_shards)
          when "3"
            loot_shards = handle_champion_shards_mastery(loot_shards)
          when "4"
            loot_shards = handle_champion_shards_mastery(loot_shards, true)
          end

          loot_shards = loot_shards.select { |l| l["count"] > 0 }

          if count_loot_items(loot_shards) > 0
            puts "We'd disenchant #{count_loot_items(loot_shards)} champion shards using the mode you chose:".light_blue
            loot_shards.each do |l|
              loot_value = l["disenchantValue"] * l["count"]
              print pad("#{l["count"]}x ", 5, false).light_black
              print pad("#{l["itemDesc"]}", 15).light_white
              print " @ ".light_black
              print pad("#{loot_value} BE", 8, false).light_black
              if l["count_keep"] > 0
                puts " keeping #{l["count_keep"]}".green
              elsif l["disenchant_note"].length > 0
                puts " #{l["disenchant_note"]}"
              else
                puts
              end
            end

            loot_shards = handle_champion_shards_exceptions(loot_shards)

            total_be_value = 0
            loot_shards.each do |l|
              total_be_value += l["disenchantValue"] * l["count"]
            end

            if count_loot_items(loot_shards) > 0
              if $ans_yes.include? user_input_check(
                                     "Disenchant #{count_loot_items(loot_shards)} champion shards for #{total_be_value} Blue Essence?",
                                     $ans_yesno,
                                     $ans_yesno_disp,
                                     true
                                   )
                $s_blue_essence += total_be_value
                $s_disenchanted += count_loot_items(loot_shards)
                threads =
                  loot_shards.map do |s|
                    Thread.new do
                      post_recipe(
                        "CHAMPION_RENTAL_disenchant",
                        s["lootId"],
                        s["count"]
                      )
                    end
                  end
                threads.each(&:join)
                puts "Done!".green
              end
            else
              puts "All remaining champions have been excluded, skipping...".yellow
            end
          else
            puts "Job's already done: no champion shards left matching your selection.".green
          end
        else
          puts "Champion shard disenchanting canceled.".yellow
        end
      end
    else
      puts "Found no champion shards to disenchant.".light_black
    end
  rescue => exception
    handle_exception(exception, "Champion Shards")
  end
end

def handle_champion_shards_owned(loot_shards)
  begin
    loot_shards.each do |l|
      unless l["redeemableStatus"] == "ALREADY_OWNED"
        l["count"] -= 1
        l["count_keep"] += 1
      end
    end
    return loot_shards.select { |l| l["count"] > 0 }
  rescue => exception
    handle_capsules(exception, "Owned Champion Shards")
  end
end

def handle_champion_shards_tokens(player_loot, loot_shards)
  begin
    token6_champion_ids = []
    token7_champion_ids = []

    loot_mastery_tokens =
      player_loot.select { |l| l["type"] == "CHAMPION_TOKEN" }

    loot_mastery_tokens.each do |token|
      if token["lootName"] = "CHAMPION_TOKEN_6"
        token6_champion_ids << token["refId"].to_i
      elsif token["lootName"] = "CHAMPION_TOKEN_7"
        token7_champion_ids << token["refId"].to_i
      end
    end

    puts "Found #{token6_champion_ids.length + token7_champion_ids.length} champions with owned mastery tokens".light_black

    loot_shards =
      loot_shards.each do |l|
        if token6_champion_ids.include? l["storeItemId"]
          l["count"] -= 2
          l["count_keep"] += 2
        elsif token7_champion_ids.include? l["storeItemId"]
          l["count"] -= 1
          l["count_keep"] += 1
        end
      end
    return loot_shards
  rescue => exception
    handle_exception(exception, "Champion Shards by Tokens")
  end
end

def handle_champion_shards_mastery(loot_shards, keep_all = false)
  begin
    summoner = get_current_summoner
    player_mastery = get_champion_mastery(summoner["summonerId"])
    threshold_champion_ids = []
    mastery6_champion_ids = []
    mastery7_champion_ids = []

    unless keep_all
      level_threshold =
        user_input_check(
          "Which mastery level should champions at least be for their shards to be kept?",
          %w[1 2 3 4 5 6],
          "[1..6]"
        )
    else
      level_threshold = "0"
    end
    level_threshold = level_threshold.to_i

    player_mastery.each do |m|
      if m["championLevel"] == 7
        mastery7_champion_ids << m["championId"]
      elsif m["championLevel"] == 6
        mastery6_champion_ids << m["championId"]
      elsif (level_threshold..5).include? m["championLevel"]
        threshold_champion_ids << m["championId"]
      elsif keep_all
        threshold_champion_ids << m["championId"]
      end
    end

    loot_shards.each do |l|
      if mastery7_champion_ids.include? l["storeItemId"]
        l["disenchant_note"] = "at mastery 7".light_black
      elsif mastery6_champion_ids.include? l["storeItemId"]
        l["count"] -= 1
        l["count_keep"] += 1
      elsif threshold_champion_ids.include? l["storeItemId"]
        l["count"] -= 2
        l["count_keep"] += 2
      else
        l["disenchant_note"] = "below threshold".yellow
      end
    end

    return loot_shards
  rescue => exception
    handle_exception(exception, "Champion Shards by Mastery")
  end
end

def handle_champion_shards_exceptions(loot_shards)
  begin
    exclusions_str = ""
    exclusions_done = false
    exclusions_done_more = ""
    exclusions_arr = []
    until exclusions_done
      if ($ans_yes).include? user_input_check(
                      "Would you like to add #{exclusions_done_more}exclusions?",
                      $ans_yesno,
                      $ans_yesno_disp
                    )
        exclusions_str +=
          "," +
            ask(
              "Okay, which champions? ".light_cyan +
                "(case-sensitive, comma-separated)".light_white +
                ": ".light_cyan
            )

        exclusions_done_more = "more "

        exclusions_arr = exclusions_str.split(/\s*,\s*/)
        exclusions_matched =
          loot_shards.select { |l| exclusions_arr.include? l["itemDesc"] }
        print "Exclusions recognized: ".green
        exclusions_matched.each { |e| print e["itemDesc"].light_white + " " }
        puts
      else
        exclusions_done = true
      end
    end
    loot_shards =
      loot_shards.select { |l| !exclusions_arr.include? l["itemDesc"] }
    return loot_shards
  rescue => exception
    handle_exception(exception, "Champion Shard Exceptions")
  end
end

def submit_stats(a, d, o, c, r, be, oe)
  begin
    uri = URI("https://checksch.de/hook/disenchanter.php")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(uri, "Content-Type": "application/json")

    req.body = { a: a, d: d, o: o, c: c, r: r, be: be, oe: oe }.to_json
    http.request(req)
  rescue => exception
    handle_exception(exception, "stat submission")
  end
end

run
