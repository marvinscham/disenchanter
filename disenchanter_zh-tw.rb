#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "net/https"
require "base64"
require "json"
require "colorize"
require "launchy"
require "open-uri"

def run
  unless !File.exist?("build.cmd")
    puts "Assuming build environment, skipping execution...".light_yellow
  else
    set_globals
    current_version = "v1.5.0"

    puts "嗨! :)".light_green
    puts "執行分解者版本 #{current_version}".light_blue
    puts "你可以在任何時刻按".light_blue +
           "[CTRL + C]".light_white + "來離開本程式.".light_blue
    check_update(current_version)
    puts $sep

    summoner = get_current_summoner
    if summoner["displayName"].nil? || summoner["displayName"].empty?
      puts "無法獲取召喚師資訊. 請重新啟動英雄聯盟客戶端.".light_red
      ask "按下 Enter鍵 離開.".cyan
      exit 1
    end
    puts "\n你當前的登入身分為 #{summoner["displayName"]}.".light_blue
    puts $sep
    puts "\n請放心嘗試所有選項, 沒有任何動作會在以下這個警告出現前被執行:".light_blue
    puts "最終確認: 執行這個動作嗎? [y|n]".light_magenta
    puts $sep

    done = false
    things_todo = {
      "1" => "海克斯材料",
      "2" => "英雄碎片",
      "3" => "造型碎片",
      #"4" => "聯盟精靈",
      "5" => "永恆精雕",
      "6" => "表情",
      "7" => "偵查守衛造型",
      "8" => "頭像",
      "s" => "前往網頁：分解者全球統計數據",
      "r" => "前往網頁：GitHub專案頁面",
      "d" => "Debug Tools",
      "x" => "離開"
    }
    things_done = []

    until done
      todo_string = ""
      things_todo.each do |k, v|
        todo_string += "[#{k}] ".light_white
        unless things_done.include? k
          todo_string += "#{v}\n".light_cyan
        else
          todo_string += "#{v} (完成)\n".light_green
        end
      end

      todo =
        user_input_check(
          "\n你現在希望做些甚麼? (提示: 先從海克斯材料開始, 可以確保你接下來不會放過任何東西! 例如海克斯寶箱開出的造型碎片!)\n\n".light_cyan +
            todo_string + "選項: ",
          things_todo.keys,
          "",
          ""
        )
      things_done << todo

      puts $sep
      puts

      puts "選項: #{things_todo[todo]}".light_white

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
        handle_debug
      when "x"
        done = true
      end
      refresh_loot
      puts $sep
    end

    puts "大功告成!".light_green
    if $actions > 0
      puts "我們節省了大約 #{$actions * 3} 秒鐘等待分解動畫放完的時間.".light_green
      puts $sep
    end
    handle_stat_submission
    puts "下次再見 :)".light_green
    ask "按下 Enter鍵 離開.".cyan
  end
end

def ask(q)
  print(q)
  q = gets
  q.chomp
end

def askutf8(q)
  print(q)
  q = STDIN.gets.encode("UTF-8").chomp
end

# def pad(str, len, right = true)
#   "%#{right ? "-" : ""}#{len}s" % str
# end

def pad(str, len, right = true)
  fullWidthStrLen = str.scan(/[\p{Han}]/).size
  fullWidthStrLen += str.scan(/[\p{Symbol}]/).size
  "%#{right ? "-" : ""}#{len-fullWidthStrLen}s" % str
end

def set_globals
  begin
    $port, $token = read_lockfile
  rescue StandardError
    puts "無法獲取會話!Could not grab session!".light_red
    puts "請確保本腳本放在你的League of Legends資料夾中, 並在打開本腳本前, 預先啟動英雄聯盟客戶端並保持開啟".light_red
    ask "按下 Enter鍵 離開.".cyan
    exit 1
  end
  $host = "https://127.0.0.1:#{$port}"
  $debug = false

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
      puts "新版本 #{ans["tag_name"]} 可下載!".light_yellow
      if ($ans_y).include? user_input_check(
                      "你希望現在下載新版本嗎?",
                      $ans_yn,
                      $ans_yn_d
                    )
        `curl https://github.com/marvinscham/disenchanter/releases/download/#{ans["tag_name"]}/disenchanter_up.exe -L -o disenchanter_up.exe`
        puts "下載完成!".green

        pid = spawn("start cmd.exe @cmd /k \"disenchanter_up.exe\"")
        Process.detach(pid)
        puts "退出中...".light_black
        exit
      end
    elsif version_local > version_remote
      puts "更新成功, 歡迎來到未來!".light_magenta
      puts "最新的線上版本: v#{version_remote}".light_blue
    else
      puts "目前使用的是最新版本, 沒問題!".green
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
    res = http.request req
    JSON.parse(res.body)
  end
end

def refresh_loot()
  request_post("lol-loot/v1/refresh?force=true", "")
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

  op =
    request_post(
      "lol-loot/v1/recipes/#{recipe}/craft?repeat=#{repeat}",
      loot_id_string
    )

  if $debug
    File.open("disenchanter_post.json", "w") { |f| f.write(op.to_json) }
    puts("Okay, written to disenchanter_post.json.")
  end
  op
end

def user_input_check(question, answers, answerdisplay, color_preset = "default")
  input = ""

  case color_preset
  when "confirm"
    question =
      "最終確認: #{question} ".light_magenta + "#{answerdisplay}".light_white +
        ": ".light_magenta
  when "default"
    question =
      "#{question} ".light_cyan + "#{answerdisplay}".light_white +
        ": ".light_cyan
  end

  until (answers).include? input
    input = ask question
    unless (answers).include? input
      puts "錯誤答案, 選項: ".light_red +
             "#{answerdisplay}".light_white
    end
  end

  input
end

def count_loot_items(loot_items)
  count = 0
  unless loot_items.nil? || loot_items.empty?
    loot_items.each { |loot| count += loot["count"] }
  end
  count
end

def get_chest_name(loot_id)
  chest_info = get_loot_info(loot_id)
  return chest_info["localizedName"] if !chest_info["localizedName"].empty?

  catalogue = {
    "CHEST_128" => "英雄典藏罐",
    "CHEST_129" => "榮耀英雄典藏罐",
    "CHEST_210" => "榮譽等級 4 晶球",
    "CHEST_211" => "榮譽等級 5 晶球"
  }

  return catalogue[loot_id] if catalogue.key?(loot_id)

  return loot_id
end

def handle_exception(exception, name)
  puts "在處理 #{name} 時發生了一個錯誤.".light_red
  puts "請截圖並在 https://github.com/marvinscham/disenchanter/issues/new 發起一個新的問題討論串".light_red
  puts "如果你沒有或不希望申請一個 GitHub 帳號, 請將本截圖及你遇到的問題用英文寄信至 dev@marvinscham.de".light_red
  puts
  puts "An error occurred while handling #{name}.".light_red
  puts "Please take a screenshot and create an issue at https://github.com/marvinscham/disenchanter/issues/new".light_red
  puts "If you don't have a GitHub account, send it to dev@marvinscham.de".light_red
  puts exception
  puts "跳過這一步驟...".yellow
end

def handle_materials
  done = false
  things_todo = {
    "1" => "神話結晶粉末",
    "2" => "活動代幣",
    "3" => "鑰匙碎片",
    "4" => "典藏罐/禮包/晶球",
    "5" => "專精代幣",
    "x" => "回到主選單"
  }
  things_done = []

  until done
    todo_string = ""
    things_todo.each do |k, v|
      todo_string += "[#{k}] ".light_white
      unless things_done.include? k
        todo_string += "#{v}\n".light_cyan
      else
        todo_string += "#{v} (完成)\n".light_green
      end
    end

    todo =
      user_input_check(
        "\n你現在希望做些甚麼?\n\n".light_cyan + todo_string +
          "選擇的操作: ",
        things_todo.keys,
        "",
        ""
      )
    things_done << todo

    puts $sep
    puts

    puts "選擇的操作: #{things_todo[todo]}".light_white

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
      puts "找到 #{loot_essence["count"]} 神話結晶粉末.".light_blue
      craft_mythic_type_names = [
        "藍色結晶粉末",
        "橘色結晶粉末",
        "隨機造型碎片"
      ]

      craft_mythic_type =
        user_input_check(
          "好的, 你想要製作甚麼\n" +
            "[1] #{craft_mythic_type_names[0]}\n" +
            "[2] #{craft_mythic_type_names[1]}\n" +
            "[3] #{craft_mythic_type_names[2]}\n" + "[x] 取消\n",
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

          puts "找到製作項目: #{recipe["contextMenuText"]} 花費 #{recipe["slots"][0]["quantity"]} 神話結晶粉末".light_blue

          craft_mythic_amount =
            user_input_check(
              "好的, 要使用多少神話結晶粉末來製作 #{craft_mythic_type_names[craft_mythic_type.to_i - 1]}?",
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
                            "製作 #{could_craft * recipe["outputs"][0]["quantity"]} " +
                              "#{craft_mythic_type_names[craft_mythic_type.to_i - 1]} 花費 " +
                              "#{(craft_mythic_amount / recipe["slots"][0]["quantity"]).floor * recipe["slots"][0]["quantity"]} 神話結晶粉末?",
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
            puts "神話結晶粉末數量不足以製作.".yellow
          end
        else
          puts "似乎不可能進行 #{craft_mythic_type_names[craft_mythic_type.to_i - 1]} 的製作.".yellow
        end
      else
        puts "已取消神話製作.".yellow
      end
    else
      puts "沒有找到可使用的神話結晶粉末.".yellow
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
      puts "找到活動代幣: #{loot_event_token["count"]}x #{loot_event_token["localizedName"]}".light_blue
      token_recipes = get_recipes_for_item(loot_event_token["lootId"])

      craft_tokens_type_names = [
        "英雄碎片和藍色結晶粉末",
        "隨機表情"
      ]
      craft_tokens_type =
        user_input_check(
          "好的, 你想要製作甚麼\n" +
            "[1] #{craft_tokens_type_names[0]}\n" +
            "[2] #{craft_tokens_type_names[1]}\n" + "[x] 取消\n",
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
            "好的, 要使用多少活動代幣來製作 #{craft_tokens_type_names[craft_tokens_type.to_i - 1]}?",
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
            puts "我們可以製作 #{r["could_craft"]}x #{r["contextMenuText"]} 花費 #{r["slots"][0]["quantity"]} 代幣每個.".light_green
          end
        end

        token_recipes = token_recipes.select { |r| r["could_craft"] > 0 }

        if total_could_craft > 0
          if ($ans_y).include? user_input_check(
                          "確定製作?",
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
          puts "數量不足以任何的製作, 跳過這一步驟.".yellow
        end
      else
        puts "已取消代幣製作.".yellow
      end
    else
      puts "沒有找到活動代幣.".yellow
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
      puts "找到 #{count_loot_items(loot_keys)} key fragments.".light_blue
      if ($ans_y).include? user_input_check(
                      "製作 #{(count_loot_items(loot_keys) / 3).floor} 個鑰匙, 花費 #{count_loot_items(loot_keys)} 個鑰匙碎片?",
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
      puts "持有的鑰匙碎片少於三個.".yellow
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
      puts "找到 #{count_loot_items(loot_capsules)} 個典藏罐/禮包/晶球:".light_blue
      loot_capsules.each do |c|
        puts "#{c["count"]}x ".light_black +
               "#{get_chest_name(c["lootId"])}".light_white
      end

      if ($ans_y).include? user_input_check(
                      "開啟 #{count_loot_items(loot_capsules)} (不需鑰匙的) 典藏罐/禮包/晶球?",
                      $ans_yn,
                      $ans_yn_d,
                      "confirm"
                    )
        $s_opened += count_loot_items(loot_capsules)
        threads =
          loot_capsules.map do |c|
            Thread.new do
              res = post_recipe(c["lootId"] + "_OPEN", c["lootId"], c["count"])
              res["added"].each do |r|
                if r["playerLoot"]["lootId"] == "CURRENCY_champion"
                  $s_blue_essence += r["deltaCount"]
                end
              end
            end
          end
        threads.each(&:join)
        puts "Done!".green
      end
    else
      puts "沒有找到不需鑰匙即可開啟的典藏罐/禮包/晶球.".yellow
    end
  rescue => exception
    handle_exception(exception, "Capsules")
  end
end

def handle_mastery_tokens
  begin
    player_loot = get_player_loot
    loot_shards = player_loot.select { |l| l["type"] == "CHAMPION_RENTAL" }
    loot_perms = player_loot.select { |l| l["type"] == "CHAMPION" }

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

    loot_overall_tokens =
      player_loot.select do |l|
        (l["lootName"] == "CHAMPION_TOKEN_6") ||
          (l["lootName"] == "CHAMPION_TOKEN_7")
      end

    puts "找到 #{count_loot_items(loot_overall_tokens)} 個專精代幣.".light_blue

    loot_mastery_tokens =
      player_loot.select do |l|
        (l["lootName"] == "CHAMPION_TOKEN_6" && l["count"] == 2) ||
          (l["lootName"] == "CHAMPION_TOKEN_7" && l["count"] == 3)
      end

    if loot_mastery_tokens.count > 0
      loot_mastery_tokens =
        loot_mastery_tokens.sort_by { |l| [l["lootName"], l["itemDesc"]] }
      puts "我們可以升級下列的英雄:\n".light_blue
      needed_shards = 0
      needed_perms = 0
      needed_essence = 0

      loot_mastery_tokens.each do |t|
        ref_shard =
          loot_shards.select { |l| t["refId"] == l["storeItemId"].to_s }
        ref_perm =
          loot_shards.select { |l| t["refId"] == l["storeItemId"].to_s }

        print pad(t["itemDesc"], 15, false).light_white
        print " 至專精等級 ".light_black
        print "#{(t["lootName"])[-1]}".light_white
        print " 花費 ".light_black
        if !ref_shard.empty? && ref_shard[0]["count"] > 0
          print "一個英雄碎片.".green
          needed_shards += 1
          t["upgrade_type"] = "shard"
        elsif !ref_perm.empty? && ref_shard[0]["count"] > 0
          print "一個永久英雄.".green
          needed_perms += 1
          t["upgrade_type"] = "permanent"
        else
          recipe_cost = (t["lootName"])[-1] == "6" ? recipe6_cost : recipe7_cost
          print "#{recipe_cost} 藍色結晶粉末.".yellow
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
        question_string =
          "Upgrade #{loot_mastery_tokens.count} champions using "
        question_string += "#{needed_shards} Shards, " if needed_shards > 0
        question_string += "#{needed_perms} Permanents, " if needed_perms > 0
        question_string +=
          "#{needed_essence} Blue Essence, " if needed_essence > 0
        question_string = question_string.delete_suffix(", ")
        question_string += "?"

        if $ans_y.include? user_input_check(
                             question_string,
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
            when "permanent"
              post_recipe(
                "CHAMPION_TOKEN_#{target_level}_redeem_withpermanent",
                [t["lootId"], "CHAMPION_#{t["refId"]}"],
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
        puts "你缺少了 #{needed_essence - owned_essence} 藍色結晶粉末以進行. Skipping...".yellow
      end
    else
      puts "沒有找到可解鎖專精等級的專精代幣.".yellow
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
      puts "找到 #{count_loot_items(loot_generic)} #{name}.".light_blue

      contains_unowned_items = false
      loot_generic.each do |l|
        if l["redeemableStatus"] != "ALREADY_OWNED"
          contains_unowned_items = true
        end
      end

      if contains_unowned_items
        user_option =
          user_input_check(
            "保留你未擁有的 #{name} 嗎?\n".light_cyan +
              "[y] ".light_white + "是\n".light_cyan + "[n] ".light_white +
              "否\n".light_cyan + "[x] ".light_white +
              "回到主選單\n".light_cyan + "選項: ",
            %w[y n x],
            "[y|n|x]",
            ""
          )

        case user_option
        when "x"
          puts "操作取消".yellow
          return
        when "y"
          disenchant_all = false
          loot_generic =
            loot_generic.select { |g| g["redeemableStatus"] == "ALREADY_OWNED" }
          puts "篩選至 #{count_loot_items(loot_generic)} 個物件.".light_blue
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

        puts "我們將分解 #{count_loot_items(loot_generic)} 個 #{name} 基於你選擇的選項:".light_blue
        loot_generic.each do |l|
          loot_value = l["disenchantValue"] * l["count"]
          print pad("#{l["count"]}x ", 5, false).light_black
          print pad("#{l[loot_name_index]}", 30).light_white
          print " @ ".light_black
          print pad("#{loot_value} 橘粉", 8, false).light_black
          if disenchant_all && l["redeemableStatus"] != "ALREADY_OWNED"
            print " (not owned)".yellow
          end
          puts
        end

        if ($ans_y).include? user_input_check(
                        "分解 #{count_loot_items(loot_generic)} 個 #{name} 換取 #{total_oe_value} 橘色結晶粉末?",
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
        puts "沒有找到持有可分解的 #{name} .".yellow
      end
    else
      puts "沒有找到可分解的 #{name} .".yellow
    end
  rescue => exception
    handle_exception(exception, name)
  end
end

def handle_skins
  handle_generic("造型碎片", "SKIN_RENTAL", "SKIN_RENTAL_disenchant")
  handle_generic("永久造型", "SKIN", "SKIN_disenchant")
end

def handle_eternals
  handle_generic(
    "永恆精雕",
    "STATSTONE_SHARD",
    "STATSTONE_SHARD_DISENCHANT"
  )
  handle_generic("永恆精雕", "STATSTONE", "STATSTONE_DISENCHANT")
end

def handle_emotes
  handle_generic("表情", "EMOTE", "EMOTE_disenchant")
end

def handle_ward_skins
  handle_generic(
    "守衛造型碎片",
    "WARDSKIN_RENTAL",
    "WARDSKIN_RENTAL_disenchant"
  )
  handle_generic("永久守衛造型", "WARDSKIN", "WARDSKIN_disenchant")
end

def handle_icons
  handle_generic("頭像", "SUMMONERICON", "SUMMONERICON_disenchant")
end

def handle_champions
  begin
    player_loot = get_player_loot
    loot_shards = player_loot.select { |l| l["type"] == "CHAMPION_RENTAL" }

    loot_perms = player_loot.select { |l| l["type"] == "CHAMPION" }
    if count_loot_items(loot_perms) > 0
      if ($ans_y).include? user_input_check(
                      "Should we include champion permanents in this process?",
                      $ans_yn,
                      $ans_yn_d
                    )
        loot_shards =
          player_loot.select do |l|
            l["type"] == "CHAMPION_RENTAL" || l["type"] == "CHAMPION"
          end
      end
    end

    if count_loot_items(loot_shards) > 0
      puts "找到 #{count_loot_items(loot_shards)} 個英雄碎片.".light_blue

      loot_shards.each do |s|
        s["count_keep"] = 0
        s["disenchant_note"] = ""
      end
      loot_shards_not_owned =
        loot_shards.select { |s| s["redeemableStatus"] != "ALREADY_OWNED" }

      if loot_shards_not_owned.length > 0
        if ($ans_y).include? user_input_check(
                        "要幫你保留一個未擁有英雄的英雄碎片嗎?",
                        $ans_yn,
                        $ans_yn_d
                      )
          loot_shards = handle_champions_owned(loot_shards)
        end
      else
        puts "沒找到未擁有英雄的英雄碎片.".light_blue
      end

      disenchant_modes = {
        "1" => "分解所有的英雄碎片",
        "2" =>
          "保留足夠(1到2個)的碎片給當前持有專精6代幣到專精7代幣的英雄",
        "3" =>
          "保留足夠(1到2個)的碎片給當前專精等級x到持有專精7代幣的英雄(可以選擇1到6)",
        "4" =>
          "保留足夠(1到2個)的碎片給所有還沒達到專精7的英雄(只會分解完全沒有用處的碎片)",
        "5" => "完全不考慮專精，為每個英雄留一個碎片",
        "x" => "取消"
      }

      modes_string = ""
      disenchant_modes.each do |k, v|
        modes_string += "[#{k}] ".light_white
        modes_string += "#{v}\n".light_cyan
      end

      disenchant_shards_mode =
        user_input_check(
          "好的, 你希望執行哪個選項?\n" + modes_string +
            "選項: ",
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
          puts "我們將分解 #{count_loot_items(loot_shards)} 個英雄碎片基於你選擇的選項:".light_blue
          loot_shards.each do |l|
            loot_value = l["disenchantValue"] * l["count"]
            print pad("#{l["count"]}x ", 5, false).light_black
            print pad("［,#{l["itemDesc"]}］", 30).light_white
            print " @ ".light_black
            print pad("#{loot_value} 藍粉", 8, false).light_black
            if l["count_keep"] > 0
              puts " 保留 #{l["count_keep"]}".green
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
                                 "分解 #{count_loot_items(loot_shards)} 英雄碎片以換取 #{total_be_value} 藍色結晶粉末?",
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
            puts "所有的英雄都已被過濾出, 跳過這一步驟...".yellow
          end
        else
          puts "完工了: 符合你篩選條件的英雄碎片均已分解.".green
        end
      else
        puts "已取消英雄碎片分解.".yellow
      end
    else
      puts "沒有找到可分解的英雄碎片.".yellow
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

    puts "找到 #{token6_champion_ids.length + token7_champion_ids.length} 個持有專精代幣的英雄".light_black

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
          "你希望留下英雄碎片的英雄, 專精等級至少要達到多少?",
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
        l["disenchant_note"] = "達到專精7".light_black
      elsif mastery6_champion_ids.include? l["storeItemId"]
        l["count"] -= 1
        l["count_keep"] += 1
      elsif threshold_champion_ids.include? l["storeItemId"]
        l["count"] -= 2
        l["count_keep"] += 2
      else
        l["disenchant_note"] = "低於下限/高於上限".yellow
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
                      "你希望增加#{exclusions_done_more}例外嗎?",
                      $ans_yn,
                      $ans_yn_d
                    )
        exclusions_str +=
          "," +
            askutf8(
              "好的, 該去除哪些英雄? ".light_cyan +
                "(請務必完整複製［］內的文字並貼上)".light_white +
                ":".light_cyan
            )

        exclusions_done_more = "更多"

        exclusions_arr = exclusions_str.split(/\s*,\s*/)
        exclusions_matched =
          loot_shards.select { |l| exclusions_arr.include? l["itemDesc"] }
        print "已正確讀取的例外: ".green
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
  puts "正在使用你的瀏覽器開啟位於 https://github.com/marvinscham/disenchanter/ 的 Github 專案頁面...".light_blue
  Launchy.open("https://github.com/marvinscham/disenchanter/")
end

def open_stats
  puts "正在使用你的瀏覽器開啟位於 https://github.com/marvinscham/disenchanter/wiki/Stats 的全球數據統計...".light_blue
  Launchy.open("https://github.com/marvinscham/disenchanter/wiki/Stats")
end

def handle_debug
  done = false
  things_todo = {
    "1" => "Write player_loot to file",
    "2" => "Write recipes of lootId to file",
    "3" => "Write loot info of lootId to file",
    "m" => "Enable debug mode",
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

    puts "Option: #{things_todo[todo]}".light_white

    case todo
    when "1"
      player_loot = get_player_loot

      File.open("disenchanter_loot.json", "w") do |f|
        f.write(player_loot.to_json)
      end

      puts("Okay, written to disenchanter_loot.json.")
    when "2"
      loot_id = ask("Which lootId would you like the recipes for?\n".light_cyan)

      recipes = get_recipes_for_item loot_id

      File.open("disenchanter_recipes.json", "w") do |f|
        f.write(recipes.to_json)
      end

      puts("Okay, written to disenchanter_recipes.json.")
    when "3"
      loot_id = ask("Which lootId would you like the info for?\n".light_cyan)

      loot_info = get_loot_info loot_id

      File.open("disenchanter_lootinfo.json", "w") do |f|
        f.write(loot_info.to_json)
      end

      puts("Okay, written to disenchanter_lootinfo.json.")
    when "m"
      $debug = true
      puts "Debug mode enabled."
    when "x"
      done = true
    end
    puts $sep
  end
end

def handle_stat_submission
  if $actions > 0
    strlen = 15
    numlen = 7
    stats_string = "你的數據:\n".light_blue
    stats_string +=
      pad("操作", strlen) + pad($actions.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad("分解", strlen) +
        pad($s_disenchanted.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad("開啟", strlen) + pad($s_opened.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad("製作", strlen) + pad($s_crafted.to_s, numlen, false).light_white +
        "\n"
    stats_string +=
      pad("領取", strlen) +
        pad($s_redeemed.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad("藍色結晶粉末", strlen) +
        pad($s_blue_essence.to_s, numlen, false).light_white + "\n"
    stats_string +=
      pad("橘色結晶粉末", strlen) +
        pad($s_orange_essence.to_s, numlen, false).light_white + "\n"

    if ($ans_y).include? user_input_check(
                    "你願意(匿名的)上傳你的數據到全球統計數據嗎?\n".light_cyan +
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
      puts "非常的感謝你!".light_green
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
