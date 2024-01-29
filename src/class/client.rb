# frozen_string_literal: true

require_relative '../modules/detect_client'

# Holds port and token info
class Client
  def initialize(stat_tracker)
    begin
      @port, @token = grab_lockfile
    rescue StandardError
      puts 'Could not grab session!'.light_red
      puts 'Make sure the script is in your League Client folder and that your Client is running.'.light_red
      ask exit_string
      exit 1
    end
    @stat_tracker = stat_tracker
    @debug = false
  end

  def host
    "https://127.0.0.1:#{@port}"
  end

  def auth
    "Basic #{@token.chomp}"
  end

  def create_client(&)
    Net::HTTP.start(
      '127.0.0.1',
      @port,
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_NONE, &
    )
  end

  def req_set_headers(req)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = auth
  end

  def request_get(path)
    create_client do |http|
      uri = URI("#{host}/#{path}")
      req = Net::HTTP::Get.new(uri)
      req_set_headers(req)
      res = http.request req
      JSON.parse(res.body)
    end
  end

  def request_post(path, body)
    # create_client do |http|
    #   uri = URI("#{host}/#{path}")
    #   req = Net::HTTP::Post.new(uri, 'Content-Type': 'application/json')
    #   req.body = body
    #   req_set_headers(req)
    #   res = http.request req
    #   JSON.parse(res.body)
    # end
  end

  def refresh_loot
    request_post('lol-loot/v1/refresh?force=true', '')
  end

  def req_get_current_summoner
    request_get('lol-summoner/v1/current-summoner')
  end

  def req_get_player_loot
    request_get('lol-loot/v1/player-loot')
  end

  def req_get_champion_mastery(summoner_id)
    request_get("lol-collections/v1/inventories/#{summoner_id}/champion-mastery")
  end

  def req_get_loot_info(loot_id)
    request_get("lol-loot/v1/player-loot/#{loot_id}")
  end

  def req_get_recipes_for_item(loot_id)
    request_get("lol-loot/v1/recipes/initial-item/#{loot_id}")
  end

  def req_post_recipe(recipe, loot_ids, repeat)
    @stat_tracker.add_actions(repeat)

    loot_id_string = "[\"#{Array(loot_ids).join('", "')}\"]"

    op =
      request_post(
        "lol-loot/v1/recipes/#{recipe}/craft?repeat=#{repeat}",
        loot_id_string
      )
    handle_post_debug
    op
  end

  def handle_post_debug
    return unless @debug

    File.write('disenchanter_post.json', op.to_json)
    puts('Okay, written to disenchanter_post.json.')
  end
end
