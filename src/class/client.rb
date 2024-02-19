# frozen_string_literal: true

require 'base64'
require 'net/http'
require 'json'

require_relative '../modules/detect_client'
require_relative '../modules/handlers/exception'
require_relative '../modules/locale'

# Holds port and token info
class Client
  attr_accessor :stat_tracker, :debug, :dry_run, :locale

  # @param stat_tracker StatTracker
  def initialize(stat_tracker)
    begin
      @port, @token, path = grab_lockfile
      @locale = grab_locale(path)
      setup_locale(self)
    rescue StandardError => e
      handle_exception(e, 'Client connection')
      ask exit_string
      exit 1
    end
    @stat_tracker = stat_tracker
    @debug = false
    @dry_run = false
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
    puts I18n.t(:'debug_menu.post_request_info', path: "#{host}/#{path}").light_black if @debug
    puts I18n.t(:'debug_menu.dry_run.notice').light_red if @dry_run
    return if @dry_run

    create_client do |http|
      uri = URI("#{host}/#{path}")
      req = Net::HTTP::Post.new(uri, 'Content-Type': 'application/json')
      req.body = body
      req_set_headers(req)
      res = http.request req
      JSON.parse(res.body)
    end
  end

  def refresh_loot
    request_post('lol-loot/v1/refresh?force=true', '')
  end

  def req_get_current_summoner
    request_get('lol-summoner/v1/current-summoner')
  end

  def req_get_settings
    request_get('lol-platform-config/v1/namespaces')
  end

  def req_get_region
    request_get('lol-platform-config/v1/namespaces/LoginDataPacket/platformId')
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

    post_answer =
      request_post(
        "lol-loot/v1/recipes/#{recipe}/craft?repeat=#{repeat}",
        loot_id_string
      )
    handle_post_debug(post_answer)
    post_answer
  end

  def handle_post_debug(post_answer)
    return unless @debug

    File.write('disenchanter_post.json', post_answer.to_json)
    puts I18n.t(:'debug_menu.file_written_notice', filename: 'disenchanter_post.json')
  end
end
