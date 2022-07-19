#!/usr/bin/env ruby
# frozen_string_literal: true

require "net/https"
require "base64"
require "json"
require "colorize"
require "launchy"
require "open-uri"

def run
  unless File.exist?("build.cmd")
    set_globals
    current_version = "v1.4.0"

    puts "Hi! :)".light_green
    puts "Running Disenchanter #{current_version}".light_blue
    puts "You can exit this script at any point by pressing ".light_blue +
           "[CTRL + C]".light_white + ".".light_blue
    check_update(current_version)
    puts $sep

    summoner = get_current_summoner
    if summoner["displayName"].nil? || summoner["displayName"].empty?
      puts "Could not grab summoner info. Try restarting your League Client.".light_red
      ask "Press Enter to exit.".cyan
      exit 1
    end
    puts "\nYou're logged in as #{summoner["displayName"]}.".light_blue
    puts $sep
    puts "\nFeel free to try the options, no actions will be taken until you confirm a banner like this:".light_blue
    puts "CONFIRM: Perform this action? [y|n]".light_magenta
    puts $sep

    done = false
    things_todo = {
      "1" => "Materials",
      "2" => "Champions",
      "3" => "Skins",
      #"4" => "Tacticians",
      "5" => "Eternals",
      "6" => "Emotes",
      "7" => "Ward Skins",
      "8" => "Icons",
      "s" => "Open Disenchanter Global Stats",
      "r" => "Open GitHub repository",
      "d" => "[DEBUG] Write loot to file",
      "x" => "Exit"
    }
    things_done = []

    until done
      todo_string = ""
      things_todo.each do |k, v|
        todo_string += "[#{k}] ".light_white
        unless things_done.include? k
          todo_string += "#{v}\n".light_cyan
        else
          todo_string += "#{v} (done)\n".light_green
        end
      end

      todo =
        user_input_check(
          "\nWhat would you like to do? (Hint: do Materials first so you don't miss anything!)\n\n".light_cyan +
            todo_string + "Option: ",
          things_todo.keys,
          "",
          ""
        )
      things_done << todo

      puts $sep
      puts

      puts "Option chosen: #{things_todo[todo]}".light_white

      case todo
      when "1"
        handle_materials
      when "2"
        handle_champions
      when "3"
        handle_skins
        # when "4"
        #   handle_tacticians
      when "5"
        handle_eternals
      when "6"
        handle_emotes
      when "7"
        handle_ward_skins
      when "8"
        handle_icons
      when "s"
        open_stats
      when "r"
        open_github
      when "d"
        write_loot_json
      when "x"
        done = true
      end
      puts $sep
    end

    puts "That's it!".light_green
    if $actions > 0
      puts "We saved you about #{$actions * 3} seconds of waiting for animations to finish.".light_green
      puts $sep
    end
    handle_stat_submission
    puts "See you next time :)".light_green
    ask "Press Enter to exit.".cyan
  else
    puts "Assuming build environment, skipping execution...".light_yellow
  end
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

  $sep =
    "____________________________________________________________".light_black

  $actions = 0
  $s_disenchanted = 0
  $s_opened = 0
  $s_crafted = 0
  $s_redeemed = 0
  $s_blue_essence = 0
  $s_orange_essence = 0

  $ans_yn = %w[y yes n no]
  $ans_y = %w[y yes]
  $ans_n = %w[n no]
  $ans_yn_d = "[y|n]"
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

def check_update(version_local)
  begin
    uri =
      URI(
        "https://api.github.com/repos/marvinscham/disenchanter/releases/latest"
      )
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new(uri, "Content-Type": "application/json")
    res = http.request req
    ans = JSON.parse(res.body)

    version_local =
      Gem::Version.new(version_local.delete_prefix("v").delete_suffix("-beta"))
    version_remote =
      Gem::Version.new(
        ans["tag_name"].delete_prefix("v").delete_suffix("-beta")
      )

    if version_remote > version_local
      puts "New version #{ans["tag_name"]} available!".light_yellow
      if ($ans_y).include? user_input_check(
                      "Would you like to download the new version now?",
                      $ans_yn,
                      $ans_yn_d
                    )
        `curl https://github.com/marvinscham/disenchanter/releases/download/#{ans["tag_name"]}/disenchanter_up.exe -L -o disenchanter_up.exe`
        puts "Done downloading!".green

        pid = spawn("start cmd.exe @cmd /k \"disenchanter_up.exe\"")
        Process.detach(pid)
        puts "Exiting...".light_black
        exit
      end
    elsif version_local > version_remote
      puts "Welcome to the future!".light_magenta
      puts "Latest remote version: v#{version_remote}".light_blue
    else
      puts "You're up to date!".green
    end
  rescue => exception
    handle_exception(exception, "self update")
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

def post_recipe(recipe, loot_ids, repeat)
  $actions += repeat

  loot_id_string = "[\"" + Array(loot_ids).join("\", \"") + "\"]"

  request_post(
    "lol-loot/v1/recipes/#{recipe}/craft?repeat=#{repeat}",
    loot_id_string
  )
end

def user_input_check(question, answers, answerdisplay, color_preset = "default")
  input = ""

  case color_preset
  when "confirm"
    question =
      "CONFIRM: #{question} ".light_magenta + "#{answerdisplay}".light_white +
        ": ".light_magenta
  when "default"
    question =
      "#{question} ".light_cyan + "#{answerdisplay}".light_white +
        ": ".light_cyan
  end

  until (answers).include? input
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
  puts "Skipping this step...".yellow
end

def handle_materials
  done = false
  things_todo = {
    "1" => "Mythic Essence",
    "2" => "Event Tokens",
    "3" => "Key Fragments",
    "4" => "Capsules",
    "5" => "Mastery Tokens",
    "x" => "Back to main menu"
  }
  things_done = []

  until done
    todo_string = ""
    things_todo.each do |k, v|
      todo_string += "[#{k}] ".light_white
      unless things_done.include? k
        todo_string += "#{v}\n".light_cyan
      else
        todo_string += "#{v} (done)\n".light_green
      end
    end

    todo =
      user_input_check(
        "\nWhat would you like to do?\n\n".light_cyan + todo_string +
          "Option: ",
        things_todo.keys,
        "",
        ""
      )
    things_done << todo

    puts $sep
    puts

    puts "Option chosen: #{things_todo[todo]}".light_white

    case todo
    when "1"
      handle_mythic_essence
    when "2"
      handle_event_tokens
    when "3"
      handle_key_fragments
    when "4"
      handle_capsules
    when "5"
      handle_mastery_tokens
    when "x"
      done = true
    end
    puts $sep
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
            if ($ans_y).include? user_input_check(
                            "Craft #{could_craft * recipe["outputs"][0]["quantity"]} " +
                              "#{craft_mythic_type_names[craft_mythic_type.to_i - 1]} from " +
                              "#{(craft_mythic_amount / recipe["slots"][0]["quantity"]).floor * recipe["slots"][0]["quantity"]} Mythic Essence?",
                            $ans_yn,
                            $ans_yn_d,
                            "confirm"
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
    else
      puts "Found no Mythic Essence to use.".yellow
    end
  rescue => exception
    handle_exception(exception, "Mythic Essence")
  end
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

      craft_tokens_type_names = [
        "Champion Shards and Blue Essence",
        "Random Emotes"
      ]
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
        if craft_tokens_type == "1"
          recipe_targets = %w[CHEST_241 CURRENCY_champion]
        elsif craft_tokens_type == "2"
          recipe_targets = %w[CHEST_187]
        end

        token_recipes = token_recipes.select { |r| !r["outputs"][0].nil? }

        token_recipes =
          token_recipes.select do |r|
            recipe_targets.include? r["outputs"][0]["lootName"]
          end
        token_recipes =
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
          if ($ans_y).include? user_input_check(
                          "Commit to forging?",
                          $ans_yn,
                          $ans_yn_d,
                          "confirm"
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
    else
      puts "Found no Event Tokens.".yellow
    end
  rescue => exception
    handle_exception(exception, "Event Tokens")
  end
end

def handle_key_fragments
  begin
    player_loot = get_player_loot

    loot_keys =
      player_loot.select { |l| l["lootId"] == "MATERIAL_key_fragment" }
    if count_loot_items(loot_keys) >= 3
      puts "Found #{count_loot_items(loot_keys)} key fragments.".light_blue
      if ($ans_y).include? user_input_check(
                      "Craft #{(count_loot_items(loot_keys) / 3).floor} keys from #{count_loot_items(loot_keys)} key fragments?",
                      $ans_yn,
                      $ans_yn_d,
                      "confirm"
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
      puts "Found less than 3 key fragments.".yellow
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

      if ($ans_y).include? user_input_check(
                      "Open #{count_loot_items(loot_capsules)} (keyless) capsules?",
                      $ans_yn,
                      $ans_yn_d,
                      "confirm"
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
      puts "Found no keyless capsules to open.".yellow
    end
  rescue => exception
    handle_exception(exception, "Capsules")
  end
end

def handle_mastery_tokens
  begin
    player_loot = get_player_loot
    loot_shards = player_loot.select { |l| l["type"] == "CHAMPION_RENTAL" }

    recipes6 = get_recipes_for_item("CHAMPION_TOKEN_6-1")
    recipes7 = get_recipes_for_item("CHAMPION_TOKEN_7-1")
    recipe6_cost =
      recipes6.select do |r|
        r["recipeName"] == "CHAMPION_TOKEN_6_redeem_withessence"
      end
    recipe6_cost = recipe6_cost[0]["slots"][1]["quantity"]
    recipe7_cost =
      recipes7.select do |r|
        r["recipeName"] == "CHAMPION_TOKEN_7_redeem_withessence"
      end
    recipe7_cost = recipe7_cost[0]["slots"][1]["quantity"]

    loot_mastery_tokens =
      player_loot.select do |l|
        (l["lootName"] == "CHAMPION_TOKEN_6" && l["count"] == 2) ||
          (l["lootName"] == "CHAMPION_TOKEN_7" && l["count"] == 3)
      end

    if loot_mastery_tokens.count > 0
      loot_mastery_tokens =
        loot_mastery_tokens.sort_by { |l| [l["lootName"], l["itemDesc"]] }
      puts "We'd upgrade the following champions:\n".light_blue
      needed_shards = 0
      needed_essence = 0

      loot_mastery_tokens.each do |t|
        ref_shard =
          loot_shards.select { |l| t["refId"] == l["storeItemId"].to_s }

        print pad(t["itemDesc"], 15, false).light_white
        print " to Mastery Level ".light_black
        print "#{(t["lootName"])[-1]}".light_white
        print " using ".light_black
        if !ref_shard.empty? && ref_shard[0]["count"] > 0
          print "a champion shard.".green
          needed_shards += 1
          t["upgrade_type"] = "shard"
        else
          recipe_cost = (t["lootName"])[-1] == "6" ? recipe6_cost : recipe7_cost
          print "#{recipe_cost} Blue Essence.".yellow
          needed_essence += recipe_cost
          t["upgrade_type"] = "essence"
        end
        puts
      end
      puts

      owned_essence =
        player_loot.select { |l| l["lootId"] == "CURRENCY_champion" }
      owned_essence = owned_essence[0]["count"]
      if (owned_essence > needed_essence)
        if $ans_y.include? user_input_check(
                             "Upgrade #{loot_mastery_tokens.count} champions using #{needed_shards} Shards and #{needed_essence} Blue Essence?",
                             $ans_yn,
                             $ans_yn_d,
                             "confirm"
                           )
          loot_mastery_tokens.each do |t|
            $s_redeemed += 1
            target_level = (t["lootName"])[-1]
            case t["upgrade_type"]
            when "shard"
              post_recipe(
                "CHAMPION_TOKEN_#{target_level}_redeem_withshard",
                [t["lootId"], "CHAMPION_RENTAL_#{t["refId"]}"],
                1
              )
            when "essence"
              post_recipe(
                "CHAMPION_TOKEN_#{target_level}_redeem_withessence",
                [t["lootId"], "CURRENCY_champion"],
                1
              )
            end
          end
        end
      else
        puts "You're missing #{needed_essence - owned_essence} Blue Essence needed to proceed. Skipping...".yellow
      end
    else
      puts "Found no upgradable Mastery Tokens.".yellow
    end
  rescue => exception
    handle_exception(exception, "token upgrades")
  end
end

def handle_generic(name, type, recipe)
  begin
    player_loot = get_player_loot
    disenchant_all = true

    loot_generic = player_loot.select { |l| l["type"] == type }
    if count_loot_items(loot_generic) > 0
      puts "Found #{count_loot_items(loot_generic)} #{name}.".light_blue

      contains_unowned_items = false
      loot_generic.each do |l|
        if l["redeemableStatus"] != "ALREADY_OWNED"
          contains_unowned_items = true
        end
      end

      if contains_unowned_items
        user_option =
          user_input_check(
            "Keep #{name} you don't own yet?\n".light_cyan +
              "[y] ".light_white + "Yes\n".light_cyan + "[n] ".light_white +
              "No\n".light_cyan + "[x] ".light_white +
              "Exit to main menu\n".light_cyan + "Option: ",
            %w[y n x],
            "[y|n|x]",
            ""
          )

        case user_option
        when "x"
          puts "Action cancelled".yellow
          return
        when "y"
          disenchant_all = false
          loot_generic =
            loot_generic.select { |g| g["redeemableStatus"] == "ALREADY_OWNED" }
          puts "Filtered to #{count_loot_items(loot_generic)} items.".light_blue
        end
      end

      if count_loot_items(loot_generic) > 0
        total_oe_value = 0
        loot_generic.each do |g|
          total_oe_value += g["disenchantValue"] * g["count"]
        end

        if loot_generic[0]["itemDesc"] == ""
          loot_name_index = "localizedName"
        else
          loot_name_index = "itemDesc"
        end
        loot_generic =
          loot_generic.sort_by do |l|
            [l["redeemableStatus"], l[loot_name_index]]
          end

        puts "We'd disenchant #{count_loot_items(loot_generic)} #{name} using the option you chose:".light_blue
        loot_generic.each do |l|
          loot_value = l["disenchantValue"] * l["count"]
          print pad("#{l["count"]}x ", 5, false).light_black
          print pad("#{l[loot_name_index]}", 30).light_white
          print " @ ".light_black
          print pad("#{loot_value} OE", 8, false).light_black
          if disenchant_all && l["redeemableStatus"] != "ALREADY_OWNED"
            print " (not owned)".yellow
          end
          puts
        end

        if ($ans_y).include? user_input_check(
                        "Disenchant #{count_loot_items(loot_generic)} #{name} for #{total_oe_value} Orange Essence?",
                        $ans_yn,
                        $ans_yn_d,
                        "confirm"
                      )
          $s_disenchanted += count_loot_items(loot_generic)
          $s_orange_essence += total_oe_value
          threads =
            loot_generic.map do |g|
              Thread.new { post_recipe(recipe, g["lootId"], g["count"]) }
            end
          threads.each(&:join)
          puts "Done!".green
        end
      else
        puts "Found no owned #{name} to disenchant.".yellow
      end
    else
      puts "Found no #{name} to disenchant.".yellow
    end
  rescue => exception
    handle_exception(exception, name)
  end
end

def handle_skins
  handle_generic("Skin Shards", "SKIN_RENTAL", "SKIN_RENTAL_DISENCHANT")
end

def handle_eternals
  handle_generic(
    "Eternal Shards",
    "STATSTONE_SHARD",
    "STATSTONE_SHARD_DISENCHANT"
  )
  handle_generic("Eternals", "STATSTONE", "STATSTONE_DISENCHANT")
end

def handle_emotes
  handle_generic("Emotes", "EMOTE", "EMOTE_disenchant")
end

def handle_ward_skins
  handle_generic(
    "Ward Skin Shards",
    "WARDSKIN_RENTAL",
    "WARDSKIN_RENTAL_disenchant"
  )
end

def handle_icons
  handle_generic("Icons", "SUMMONERICON", "SUMMONERICON_disenchant")
end

def handle_champions
  begin
    player_loot = get_player_loot

    loot_shards = player_loot.select { |l| l["type"] == "CHAMPION_RENTAL" }
    if count_loot_items(loot_shards) > 0
      puts "Found #{count_loot_items(loot_shards)} champion shards.".light_blue

      loot_shards.each do |s|
        s["count_keep"] = 0
        s["disenchant_note"] = ""
      end
      loot_shards_not_owned =
        loot_shards.select { |s| s["redeemableStatus"] != "ALREADY_OWNED" }

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
        "1" => "Disenchant all champion shards",
        "2" =>
          "Keep enough (1/2) shards for champions you own mastery 6/7 tokens for",
        "3" =>
          "Keep enough (1/2) shards to fully master champions at least at mastery level x (select from 1 to 6)",
        "4" =>
          "Keep enough (1/2) shards to fully master all champions (only disenchant shards that have no possible use)",
        "5" => "Keep one shard of each champion regardless of mastery",
        "x" => "Cancel"
      }

      modes_string = ""
      disenchant_modes.each do |k, v|
        modes_string += "[#{k}] ".light_white
        modes_string += "#{v}\n".light_cyan
      end

      disenchant_shards_mode =
        user_input_check(
          "Okay, which option would you like to go by?\n" + modes_string +
            "Option: ",
          disenchant_modes.keys,
          "[1|2|3|4|5|x]",
          ""
        )
      unless disenchant_shards_mode == "x"
        case disenchant_shards_mode
        when "1"
          # no filtering needed -> done
        when "2"
          loot_shards = handle_champions_tokens(player_loot, loot_shards)
        when "3"
          loot_shards = handle_champions_mastery(loot_shards)
        when "4"
          loot_shards = handle_champions_mastery(loot_shards, true)
        when "5"
          loot_shards = handle_champions_collection(loot_shards)
        end

        loot_shards = loot_shards.select { |l| l["count"] > 0 }
        loot_shards =
          loot_shards.sort_by { |l| [l["disenchant_note"], l["itemDesc"]] }

        if count_loot_items(loot_shards) > 0
          puts "We'd disenchant #{count_loot_items(loot_shards)} champion shards using the option you chose:".light_blue
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

          loot_shards = handle_champions_exceptions(loot_shards)

          total_be_value = 0
          loot_shards.each do |l|
            total_be_value += l["disenchantValue"] * l["count"]
          end

          if count_loot_items(loot_shards) > 0
            if $ans_y.include? user_input_check(
                                 "Disenchant #{count_loot_items(loot_shards)} champion shards for #{total_be_value} Blue Essence?",
                                 $ans_yn,
                                 $ans_yn_d,
                                 "confirm"
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
    else
      puts "Found no champion shards to disenchant.".yellow
    end
  rescue => exception
    handle_exception(exception, "Champion Shards")
  end
end

def handle_champions_owned(loot_shards)
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

def handle_champions_tokens(player_loot, loot_shards)
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

def handle_champions_mastery(loot_shards, keep_all = false)
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

def handle_champions_collection(loot_shards)
  begin
    loot_shards.each do |l|
      l["count"] -= 1
      l["count_keep"] += 1
    end

    return loot_shards
  rescue => exception
    handle_exception(exception, "Champion Shards for Collection")
  end
end

def handle_champions_exceptions(loot_shards)
  begin
    exclusions_str = ""
    exclusions_done = false
    exclusions_done_more = ""
    exclusions_arr = []
    until exclusions_done
      if ($ans_y).include? user_input_check(
                      "Would you like to add #{exclusions_done_more}exclusions?",
                      $ans_yn,
                      $ans_yn_d
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

def open_github
  puts "Opening GitHub repository at https://github.com/marvinscham/disenchanter/ in your browser...".light_blue
  Launchy.open("https://github.com/marvinscham/disenchanter/")
end

def open_stats
  puts "Opening Global Stats at https://github.com/marvinscham/disenchanter/wiki/Stats in your browser...".light_blue
  Launchy.open("https://github.com/marvinscham/disenchanter/wiki/Stats")
end

def write_loot_json
  player_loot = get_player_loot

  File.open("disenchanter_loot.json", "w") { |f| f.write(player_loot.to_json) }
end

def handle_stat_submission
  if $actions > 0
    strlen = 15
    numlen = 7
    stats_string = "Your stats:\n".light_blue
    stats_string +=
      pad("Actions", strlen) + pad($actions.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad("Disenchanted", strlen) +
        pad($s_disenchanted.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad("Opened", strlen) + pad($s_opened.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad("Crafted", strlen) + pad($s_crafted.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad("Redeemed", strlen) +
        pad($s_redeemed.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad("Blue Essence", strlen) +
        pad($s_blue_essence.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad("Orange Essence", strlen) +
        pad($s_orange_essence.to_s, numlen, false).light_white + "\n"

    if ($ans_y).include? user_input_check(
                    "Would you like to contribute your (anonymous) stats to the global stats?\n".light_cyan +
                      stats_string + "[y|n]: ",
                    $ans_yn,
                    $ans_yn_d,
                    ""
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
