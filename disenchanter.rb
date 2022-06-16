#!/usr/bin/env ruby
# frozen_string_literal: true

require "net/https"
require "base64"
require "json"

def run
  sep = "____________________________________________________________"
  $ans_yesno = %w[y yes n no true false]
  $ans_yes = %w[y yes true]
  ans_false = %w[n no false]
  $ans_yesno_disp = "[y|n]"

  puts "Hi! :)"
  puts "You can exit this script at any point by pressing CTRL + C."
  puts sep

  set_globals

  summoner = get_current_summoner
  if summoner["displayName"].nil? || summoner["displayName"].empty?
    puts "Could not grab summoner info. Try restarting your League Client."
    exit 1
  end
  puts "You're logged in as #{summoner["displayName"]}."
  puts sep

  handle_event_tokens
  puts sep

  handle_key_fragments
  puts sep

  handle_capsules
  puts sep

  handle_emotes
  puts sep

  handle_champion_shards
  puts sep

  puts "That's it!"
  if $actions > 0
    puts "We saved you about #{$actions * 3} seconds of waiting for animations to finish."
  end
  puts "See you next time :)"
end

def ask(q)
  print(q)
  q = gets
  q.chomp
end

def set_globals
  begin
    $port, $token = read_lockfile
  rescue StandardError
    puts "Could not grab session. Make sure your League Client is running."
    exit 1
  end
  $host = "https://127.0.0.1:#{$port}"
  $actions = 0
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

def user_input_check(question, answers, answerdisplay)
  input = ""

  until (answers).include? input
    input = ask "#{question} #{answerdisplay}: "
    puts "Invalid answer: #{answerdisplay}" unless (answers).include? input
  end

  input
end

def count_loot_items(loot_items)
  count = 0
  loot_items.each { |loot| count += loot["count"] }
  count
end

def handle_event_tokens
  player_loot = get_player_loot

  loot_event_token =
    player_loot.select do |l|
      l["type"] == "MATERIAL" && l["displayCategories"] == "CHEST" &&
        l["lootId"].start_with?("MATERIAL_") &&
        !l["lootId"].start_with?("MATERIAL_key")
    end
  loot_event_token = loot_event_token[0]

  if !loot_event_token.nil? && loot_event_token["count"] > 0
    puts "Found Event Tokens: #{loot_event_token["count"]}x #{loot_event_token["localizedName"]}"
    token_recipes = get_recipes_for_item(loot_event_token["lootId"])

    if ($ans_yes).include? user_input_check(
                    "Craft #{loot_event_token["localizedName"]}s to Blue Essence or Emotes?",
                    $ans_yesno,
                    $ans_yesno_disp
                  )
      craft_tokens_type =
        user_input_check(
          "Okay, would you like to craft to Blue Essence [1] or Emotes [2]?",
          %w[1 essence 2 emotes],
          "[1|2]"
        )

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
        puts "Recipe found: #{r["contextMenuText"]} for #{r["slots"][0]["quantity"]} Tokens"
      end

      total_could_craft = 0

      token_recipes.each do |r|
        r["could_craft"] = (
          loot_event_token["count"] / r["slots"][0]["quantity"]
        ).floor
        total_could_craft += r["could_craft"]
        loot_event_token["count"] -= (
          loot_event_token["count"] / r["slots"][0]["quantity"]
        ).floor * r["slots"][0]["quantity"]
        if r["could_craft"] > 0
          puts "We could craft #{r["could_craft"]}x #{r["contextMenuText"]} for #{r["slots"][0]["quantity"]} Tokens each."
        end
      end

      if total_could_craft > 0
        if ($ans_yes).include? user_input_check(
                        "CONFIRM: Commit to forging?",
                        $ans_yesno,
                        $ans_yesno_disp
                      )
          threads =
            token_recipes.map do |r|
              if r["could_craft"] > 0
                Thread.new do
                  post_recipe(
                    r["recipeName"],
                    loot_event_token["lootId"],
                    r["could_craft"]
                  )
                end
              end
            end
          threads.each(&:join)
          puts "Done!"
        end
      else
        puts "Can't afford any recipe, skipping."
      end
    end
  else
    puts "Found no Event Tokens."
  end
end

def handle_key_fragments
  player_loot = get_player_loot

  loot_keys = player_loot.select { |l| l["lootId"] == "MATERIAL_key_fragment" }
  if count_loot_items(loot_keys) >= 3
    puts "Found #{count_loot_items(loot_keys)} key fragments."
    if ($ans_yes).include? user_input_check(
                    "CONFIRM: Craft #{(count_loot_items(loot_keys) / 3).floor} keys from #{count_loot_items(loot_keys)} key fragments?",
                    $ans_yesno,
                    $ans_yesno_disp
                  )
      post_recipe(
        "MATERIAL_key_fragment_forge",
        "MATERIAL_key_fragment",
        (count_loot_items(loot_keys) / 3).floor
      )
      puts "Done!"
    end
  else
    puts "Found less than 3 key fragments."
  end
end

def handle_capsules
  player_loot = get_player_loot

  chest_names = {}
  chest_names["CHEST_128"] = "Champion Capsule"
  chest_names["CHEST_187"] = "Hextech Mystery Emote"
  chest_names["CHEST_241"] = "Random Champion Shard"

  capsule_ids = %w[CHEST_128 CHEST_187 CHEST_241]
  loot_capsules = player_loot.select { |l| capsule_ids.include? l["lootId"] }
  if count_loot_items(loot_capsules) > 0
    puts "Found #{count_loot_items(loot_capsules)} capsules:"
    loot_capsules.each { |c| puts "#{c["count"]}x #{chest_names[c["lootId"]]}" }

    if ($ans_yes).include? user_input_check(
                    "CONFIRM: Open #{count_loot_items(loot_capsules)} (keyless) capsules?",
                    $ans_yesno,
                    $ans_yesno_disp
                  )
      threads =
        loot_capsules.map do |c|
          Thread.new do
            post_recipe(c["lootId"] + "_OPEN", c["lootId"], c["count"])
          end
        end
      threads.each(&:join)
      puts "Done!"
    end
  else
    puts "Found no keyless capsules to open."
  end
end

def handle_emotes
  player_loot = get_player_loot

  loot_emotes =
    player_loot.select do |l|
      l["type"] == "EMOTE" && l["redeemableStatus"] == "ALREADY_OWNED"
    end
  if count_loot_items(loot_emotes) > 0
    total_oe_value = 0
    loot_emotes.each { |e| total_oe_value += e["disenchantValue"] }
    if ($ans_yes).include? user_input_check(
                    "CONFIRM: Disenchant #{count_loot_items(loot_emotes)} (already owned) emotes for #{total_oe_value} Orange Essence?",
                    $ans_yesno,
                    $ans_yesno_disp
                  )
      threads =
        loot_emotes.map do |e|
          Thread.new do
            post_recipe("EMOTE_disenchant", e["lootId"], e["count"])
          end
        end
      threads.each(&:join)
      puts "Done!"
    end
  else
    puts "Found no owned emotes to disenchant."
  end
end

def handle_champion_shards
  player_loot = get_player_loot

  loot_shards = player_loot.select { |l| l["type"] == "CHAMPION_RENTAL" }
  if count_loot_items(loot_shards) > 0
    if ($ans_yes).include? user_input_check(
                    "Disenchant unneeded champion shards?",
                    $ans_yesno,
                    $ans_yesno_disp
                  )
      disenchant_shards_mode =
        user_input_check(
          "Okay, which mode would you like to go by?\n" +
            "[1] Disenchant all champion shards\n" +
            "[2] Keep shards for champions you don't own\n" +
            "[3] Keep shards for champions you currently own mastery 6/7 tokens for\n" +
            "[4] Keep shards for champions above a specified mastery level\n",
          %w[1 all 2 owned 3 tokens 4 mastery],
          "[1|2|3|4]"
        )
      puts "Found #{count_loot_items(loot_shards)} champion shards."

      case disenchant_shards_mode
      when "1"
        # done
      when "2"
        loot_shards = handle_champion_shards_owned(loot_shards)
      when "3"
        loot_shards = handle_champion_shards_tokens(player_loot, loot_shards)
      when "4"
        loot_shards = handle_champion_shards_mastery(loot_shards)
      end

      loot_shards = loot_shards.select { |l| l["count"] > 0 }

      if count_loot_items(loot_shards) > 0
        puts "We'd disenchant #{count_loot_items(loot_shards)} champion shards using the mode you chose:"
        loot_shards.each do |l|
          loot_value = l["disenchantValue"] * l["count"]
          puts "#{l["count"]}x #{l["itemDesc"]} @ #{loot_value} BE"
        end

        loot_shards = handle_champion_shards_exceptions(loot_shards)

        total_be_value = 0
        loot_shards.each do |l|
          total_be_value += l["disenchantValue"] * l["count"]
        end

        if $ans_yes.include? user_input_check(
                               "CONFIRM: Disenchant #{count_loot_items(loot_shards)} champion shards for #{total_be_value} Blue Essence?",
                               $ans_yesno,
                               $ans_yesno_disp
                             )
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
          puts "Done!"
        end
      else
        puts "No champion shards left matching your selection."
      end
    end
  else
    puts "Found no champion shards to disenchant."
  end
end

def handle_champion_shards_owned(loot_shards)
  loot_shards.select { |l| l["redeemableStatus"] == "ALREADY_OWNED" }
end

def handle_champion_shards_tokens(player_loot, loot_shards)
  token6_champion_ids = []
  token7_champion_ids = []

  loot_mastery_tokens = player_loot.select { |l| l["type"] == "CHAMPION_TOKEN" }

  loot_mastery_tokens.each do |token|
    if token["lootName"] = "CHAMPION_TOKEN_6"
      token6_champion_ids << token["refId"].to_i
    elsif token["lootName"] = "CHAMPION_TOKEN_7"
      token7_champion_ids << token["refId"].to_i
    end
  end

  puts "Found #{token6_champion_ids.length + token7_champion_ids.length} champions with owned mastery tokens"

  loot_shards =
    loot_shards.each do |l|
      if token6_champion_ids.include? l["storeItemId"]
        l["count"] -= 2
      elsif token7_champion_ids.include? l["storeItemId"]
        l["count"] -= 1
      end
    end
  loot_shards
end

def handle_champion_shards_mastery(loot_shards)
  summoner = get_current_summoner
  player_mastery = get_champion_mastery(summoner["summonerId"])
  mastery5_champion_ids = []
  mastery6_champion_ids = []

  level_threshold =
    user_input_check(
      "Which mastery level should champions at least be for their shards to be kept?",
      %w[1 2 3 4 5 6],
      "[1..6]"
    )

  player_mastery.each do |m|
    if m["championLevel"] >= level_threshold.to_i && m["championLevel"] <= 5
      mastery5_champion_ids << m["championId"]
    elsif m["championLevel"] == 6
      mastery6_champion_ids << m["championId"]
    end
  end

  puts "Found #{mastery5_champion_ids.length + mastery6_champion_ids.length} relevant champions with threshold at level #{level_threshold}"

  loot_shards.each do |l|
    if mastery5_champion_ids.include? l["storeItemId"]
      l["count"] -= 2
    elsif mastery6_champion_ids.include? l["storeItemId"]
      l["count"] -= 1
    end
  end
end

def handle_champion_shards_exceptions(loot_shards)
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
        "," + ask("Okay, which champions? (case-sensitive, comma-separated): ")

      exclusions_done_more = "more "

      exclusions_arr = exclusions_str.split(/\s*,\s*/)
      exclusions_matched =
        loot_shards.select { |l| exclusions_arr.include? l["itemDesc"] }
      print "Exclusions recognized: "
      exclusions_matched.each { |e| print e["itemDesc"] + " " }
      puts
    else
      exclusions_done = true
    end
  end
  loot_shards =
    loot_shards.select { |l| !exclusions_arr.include? l["itemDesc"] }
end

run
