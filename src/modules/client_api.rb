# frozen_string_literal: true

def create_client
  Net::HTTP.start(
    '127.0.0.1',
    $port,
    use_ssl: true,
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  ) { |http| yield(http) }
end

def req_set_headers(req)
  req['Content-Type'] = 'application/json'
  req['Authorization'] = "Basic #{$token.chomp}"
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
    req = Net::HTTP::Post.new(uri, "Content-Type": 'application/json')
    req.body = body
    req_set_headers(req)
    res = http.request req
    JSON.parse(res.body)
  end
end

def refresh_loot()
  request_post('lol-loot/v1/refresh?force=true', '')
end

def get_current_summoner()
  request_get('lol-summoner/v1/current-summoner')
end

def get_player_loot()
  request_get('lol-loot/v1/player-loot')
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
    File.open('disenchanter_post.json', 'w') { |f| f.write(op.to_json) }
    puts('Okay, written to disenchanter_post.json.')
  end
  op
end
