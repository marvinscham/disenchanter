#!/usr/bin/env ruby

require "net/https"
require "base64"
require "json"
require "optparse"

def run
    ARGV << '-h' if ARGV.empty?
    options = OptParser.parse(ARGV)

    shardOptions = true
    suppOptions = true

    if !options[:all] && !options[:owned] && !options[:tokens] && !options[:mastery] && !options[:fullmastery]
        shardOptions = false
        puts "Note: No shard disenchantment options provided."
    end

    if !options[:capsules]
        suppOptions = false
        puts "Note: No supporting disenchantment options provided."
    end

    if !shardOptions && !suppOptions
        puts "You're missing options to make the script do anything. Run ruby disenchanter.rb -h for help."
        exit
    end

    port, token = read_lockfile
    host = "https://127.0.0.1:#{port}"
    player_loot = []
    loot_shards = []
    loot_chests = []
    loot_keys = []
    loot_mastery_tokens = []
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
        puts "Found a total of #{count_loot_items(player_loot)} loot items"
        
        mastery_req = get_mastery(host, http, current_summoner["summonerId"])
        set_headers(mastery_req, token)
        mastery_res = http.request mastery_req
        player_mastery = JSON.parse(mastery_res.body)
    end

    loot_shards = player_loot.select do |loot|
        loot["type"] == "CHAMPION_RENTAL"
    end
    puts "Found #{count_loot_items(loot_shards)} champion shards"

    if options[:capsules]
        loot_chests = player_loot.select do |loot|
            loot["type"] == "CHEST"
        end

        capsule_ids = ["CHEST_128"]
        
        loot_chests = loot_chests.select do |chest|
            capsule_ids.include? chest["lootId"]
        end
        puts "Found #{count_loot_items(loot_chests)} capsules to open"
    end

    if options[:keyfragments]
        loot_keys = player_loot.select do |loot|
            loot["lootId"] == "MATERIAL_key_fragment"
        end
        puts "Found #{count_loot_items(loot_keys)} key fragments"
    end

    if options[:owned]
        loot_shards = loot_shards.select do |loot|
            loot["redeemableStatus"] == "ALREADY_OWNED"
        end
        puts "Filtered down to #{count_loot_items(loot_shards)} shards of champions you already own"
    end

    if options[:tokens]
        token6_champion_ids = []
        token7_champion_ids = []

        loot_mastery_tokens = loot_player.select do |loot|
            loot["type"] == "CHAMPION_TOKEN"
        end

        loot_mastery_tokens.each do |token|
            if token["lootName"] = "CHAMPION_TOKEN_6"
                token6_champion_ids << token["refId"].to_i
            elsif token["lootName"] = "CHAMPION_TOKEN_7"
                token7_champion_ids << token["refId"].to_i
            end
        end

        puts "Found #{token6_champion_ids.length + token7_champion_ids.length} champions with owned mastery tokens"

        loot_shards = loot_shards.each do |loot|
            if token6_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 2
            elsif token7_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 1
            end
        end

        loot_shards = loot_shards.select do |loot|
            loot["count"] > 0
        end

        puts "Filtered down to #{count_loot_items(loot_shards)} shards you have no tokens for"
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

        loot_shards.each do |loot|
            if mastery5_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 2
            elsif mastery6_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 1
            end
        end

        loot_shards = loot_shards.select do |loot|
            loot["count"] > 0
        end

        puts "Filtered down to #{count_loot_items(loot_shards)} shards that aren't needed for champions above level #{options[:mastery]}"
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

        loot_shards.each do |loot|
            if mastery6_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 1
            elsif !mastery7_champion_ids.include? loot["storeItemId"]
                loot["count"] -= 2
            end
        end

        loot_shards = loot_shards.select do |loot|
            loot["count"] > 0
        end

        puts "Filtered down to #{count_loot_items(loot_shards)} shards that aren't needed for fully mastering champions"
    end

    if options[:exclude]
        loot_shards = loot_shards.select do |loot|
            !options[:exclude].include? loot["itemDesc"]
        end

        puts "Filtered down to #{count_loot_items(loot_shards)} shards that aren't manually excluded"
    end

    if !shardOptions
        loot_shards = []
    end
    
    total_value = 0
    loot_shards = loot_shards.sort_by {|loot| loot["itemDesc"]}
    if options[:verbose]
        loot_shards.each do |loot|
            loot_value = loot["disenchantValue"] * loot["count"]
            total_value += loot_value
            puts "Disenchanting #{loot["count"]} #{loot["itemDesc"]} shards for #{loot_value} BE"
        end
    end

    if !options[:dry]
        chest_threads = loot_chests.map do |chest|
            Thread.new do
                create_client(port) do |open_http|
                    open_req = open_chest(host, open_http, chest["lootName"], chest["count"])
                    set_headers(open_req, token)
                    open_http.request open_req
                end
            end
        end
        chest_threads.each(&:join)
    
        shard_threads = loot_shards.map do |shard|
            Thread.new do
                create_client(port) do |disenchant_http|
                    disenchant_req = disenchant_champion_shard(host, disenchant_http, shard["lootName"], shard["count"])
                    set_headers(disenchant_req, token)
                    disenchant_http.request disenchant_req
                end
            end
        end    
        shard_threads.each(&:join)

        puts "Opened #{count_loot_items(loot_chests)} chests!"
        puts "Disenchanted #{count_loot_items(loot_shards)} champion shards for a total of #{total_value} BE!"
    else
        puts "Would open #{count_loot_items(loot_chests)} chests."
        puts "Dry Run: would disenchant #{count_loot_items(loot_shards)} champion shards for a total of #{total_value} BE."
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

def disenchant_champion_shard(host, http, loot_name, repeat)
    uri = URI("#{host}/lol-loot/v1/recipes/CHAMPION_RENTAL_disenchant/craft?repeat=#{repeat}")
    req = Net::HTTP::Post.new(uri, 'Content-Type': "application/json")
    req.body = "[\"#{loot_name}\"]"
    req
end

def open_chest(host, http, loot_name, repeat)
    uri = URI("#{host}/lol-loot/v1/recipes/#{loot_name}_OPEN/craft?repeat=#{repeat}")
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
            opts.banner = "Usage: disenchanter.rb [options]"

            opts.on('-d', '--dry', TrueClass, 'Show results without disenchanting (applies -v)') do |d|
                options[:dry] = d.nil? ? false : d
                options[:verbose] = true
            end

            opts.on('-v', '--verbose', TrueClass, 'Run verbosely') do |v|
                options[:verbose] = v.nil? ? false : v
            end

            opts.on('-c', '--capsules', TrueClass, 'Open champion capsules') do |c|
                options[:capsules] = c.nil? ? false : c
            end

            opts.on('-k', '--keyfragments', TrueClass, 'Forge keys from key fragments') do |k|
                options[:keyfragments] = k.nil? ? false : k
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