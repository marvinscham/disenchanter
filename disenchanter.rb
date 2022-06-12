#!/usr/bin/env ruby

require "net/https"
require "base64"
require "json"
require "optparse"

def run
    ARGV << '-h' if ARGV.empty?
    options = OptParser.parse(ARGV)

    if !options[:all] && !options[:owned] && !options[:tokens] && !options[:mastery] && !options[:fullmastery]
        puts "Please provide an option to properly run the script. Run disenchanter.rb -h for help."
        exit
    end

    port, token = read_lockfile
    host = "https://127.0.0.1:#{port}"
    player_loot = []
    loot_tokens = []
    player_mastery = []
    
    create_client(port) do |http|
        summoner_req = get_current_summoner(host, http)
        set_headers(summoner_req, token)
        summoner_res = http.request summoner_req
        current_summoner = JSON.parse(summoner_res.body)
        puts "Logged in as #{current_summoner["displayName"]}"        

        loot_req =  get_loot(host, http)
        set_headers(loot_req, token)
        loot_res = http.request loot_req
        player_loot = JSON.parse(loot_res.body)
        loot_tokens = player_loot
        puts "Found a total of #{count_loot_items(player_loot)} loot items"
        
        mastery_req = get_mastery(host, http, current_summoner["summonerId"])
        set_headers(mastery_req, token)
        mastery_res = http.request mastery_req
        player_mastery = JSON.parse(mastery_res.body)
    end

    player_loot = player_loot.select do |loot|
        loot["type"] == "CHAMPION_RENTAL"
    end
    puts "Found #{count_loot_items(player_loot)} champion shards"

    if options[:owned]
        player_loot = player_loot.select do |loot|
            loot["redeemableStatus"] == "ALREADY_OWNED"
        end
        puts "Filtered down to #{count_loot_items(player_loot)} shards of champions you already own"
    end

    if options[:tokens]
        token6_champion_ids = []
        token7_champion_ids = []

        loot_tokens = loot_tokens.select do |loot|
            loot["type"] == "CHAMPION_TOKEN"
        end

        loot_tokens.each do |token|
            if token["lootName"] = "CHAMPION_TOKEN_6"
                token6_champion_ids << token["refId"].to_i
            elsif token["lootName"] = "CHAMPION_TOKEN_7"
                token7_champion_ids << token["refId"].to_i
            end
        end

        puts "Found #{token6_champion_ids.length + token7_champion_ids.length} champions with owned mastery tokens"

        player_loot = player_loot.each do |loot|
            if token6_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 2
            elsif token7_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 1
            end
        end

        player_loot = player_loot.select do |loot|
            loot["count"] > 0
        end

        puts "Filtered down to #{count_loot_items(player_loot)} shards you have no tokens for"
    end

    if options[:mastery]
        mastery5_champion_ids = []
        mastery6_champion_ids = []

        player_mastery.each do |mastery|
            if mastery["championLevel"] >= options[:mastery] && mastery["championLevel"] <= 5
                mastery5_champion_ids << mastery["championId"]
            elsif mastery["championLevel"] == 6
                mastery6_champion_ids << mastery["championId"]
            end
        end

        puts "Found #{mastery5_champion_ids.length + mastery6_champion_ids.length} champions at or above specified level threshold of #{options[:mastery]}"

        player_loot.each do |loot|
            if mastery5_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 2
            elsif mastery6_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 1
            end
        end

        player_loot = player_loot.select do |loot|
            loot["count"] > 0
        end

        puts "Filtered down to #{count_loot_items(player_loot)} shards that aren't needed for champions above level #{options[:mastery]}"
    end

    if options[:fullmastery]        
        mastery6_champion_ids = []
        mastery7_champion_ids = []

        player_mastery.each do |mastery|
            if mastery["championLevel"] == 6
                mastery6_champion_ids << mastery["championId"]
            elsif mastery["championLevel"] == 7
                mastery7_champion_ids << mastery["championId"]
            end
        end

        puts "Found #{mastery6_champion_ids.length} champions at mastery level 6"
        puts "Found #{mastery7_champion_ids.length} champions at mastery level 7"

        player_loot.each do |loot|
            if mastery6_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 1
            elsif !mastery7_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 2
            end
        end

        player_loot = player_loot.select do |loot|
            loot["count"] > 0
        end

        puts "Filtered down to #{count_loot_items(player_loot)} shards that aren't needed for fully mastering champions"
    end

    if options[:exclude]
        player_loot = player_loot.select do |loot|
            !options[:exclude].include? loot["itemDesc"]
        end

        puts "Filtered down to #{count_loot_items(player_loot)} shards that aren't manually excluded"
    end
    
    total_value = 0
    player_loot = player_loot.sort_by {|loot| loot["itemDesc"]}
    if options[:verbose]
        player_loot.each do |loot|
            loot_value = loot["disenchantValue"] * loot["count"]
            total_value += loot_value
            puts "Disenchanting #{loot["count"]} #{loot["itemDesc"]} shards for #{loot_value} BE"
        end
    end

    threads = player_loot.map do |loot|
        Thread.new do
            create_client(port) do |disenchant_http|                
                if !options[:dry]
                    disenchant_req = disenchant(host, disenchant_http, loot["lootName"], loot["count"])
                    set_headers(disenchant_req, token)
                    disenchant_http.request disenchant_req
                end
            end
        end
    end

    threads.each(&:join)
    if options[:dry]
        puts "Dry Run: would disenchant #{count_loot_items(player_loot)} champion shards for a total of #{total_value} BE."
    else
        puts "Disenchanted #{count_loot_items(player_loot)} champion shards for a total of #{total_value} BE!"
    end
end

def read_lockfile
    contents = File.read("lockfile")
    _leagueclient,_unkPort,port,password = contents.split(":")
    token = Base64.encode64("riot:#{password.chomp}")
    
    [port, token]
end

def create_client(port)
    Net::HTTP.start("127.0.0.1", port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        yield(http)
    end
end

def set_headers(req, token)
    req['Content-Type'] = "application/json"
    req["Authorization"] = "Basic #{token.chomp}"
end

def get_loot(host, http)
    uri = URI("#{host}/lol-loot/v1/player-loot")
    Net::HTTP::Get.new(uri)
end

def get_mastery(host, http, summoner_id)
    uri = URI("#{host}/lol-collections/v1/inventories/#{summoner_id}/champion-mastery")
    Net::HTTP::Get.new(uri)
end

def get_current_summoner(host, http)
    uri = URI("#{host}/lol-summoner/v1/current-summoner")
    Net::HTTP::Get.new(uri)
end

def disenchant(host, http, loot_name, repeat)
    uri = URI("#{host}/lol-loot/v1/recipes/CHAMPION_RENTAL_disenchant/craft?repeat=#{repeat}")
    req = Net::HTTP::Post.new(uri, 'Content-Type': "application/json")
    req.body = "[\"#{loot_name}\"]"
    req
end

def count_loot_items(player_loot)
    count = 0
    player_loot.each do |loot|
        count += loot["count"]
    end
    count
end

class OptParser
    def self.parse(args)
        options = {}
        opts = OptionParser.new do |opts|
            opts.banner = "Usage: disenchanter.rb [-d] [-v] [-h] [-a | -o | -t | -m LEVEL | -f] [-x NAME]"

            opts.on('-d', '--dry', TrueClass, 'Show results without disenchanting (applies -v)') do |d|
                options[:dry] = d.nil? ? false : d
                options[:verbose] = true
            end

            opts.on('-v', '--verbose', TrueClass, 'Run verbosely') do |v|
                options[:verbose] = v.nil? ? false : v
            end

            opts.on('-a', '--all', TrueClass, 'Disenchant everything') do |a|
                options[:all] = a.nil? ? false : a
            end

            opts.on('-o', '--owned', TrueClass, 'Keep shards for unowned champions') do |o|
                options[:owned] = o.nil? ? false : o
            end

            opts.on('-t', '--tokens', TrueClass, 'Keep shards for champions with owned mastery tokens') do |t|
                options[:tokens] = t.nil? ? false : t
            end

            opts.on('-m', '--mastery LEVEL', OptionParser::OctalInteger, 'Keep shards for champions at mastery level x or above') do |m|
                options[:mastery] = m
            end

            opts.on('-f', '--fullmastery', TrueClass, 'Keep shards for champions not at mastery level 7') do |f|
                options[:fullmastery] = f.nil? ? false : f
            end

            opts.on('-x', '--exclude X,Y,Z', Array, "Manually exclude champions's shards") do |x|
                options[:exclude] = x
            end

            opts.on('-h', '--help', "Show this message") do
                puts opts
                exit!
            end

        end

        begin
            opts.parse(args)
        rescue Exception => e
            puts "Exception encountered: #{e}"
            exit 1
        end

        options
    end
end


run()