# frozen_string_literal: true

require 'base64'
require 'net/http'
require 'json'

require_relative '../modules/locale'
require_relative '../modules/detect_client'
require_relative '../modules/update/checker'
require_relative '../modules/handlers/exception'

# Holds port and token info
# rubocop:disable Metrics/ClassLength
class Client
  attr_accessor :stat_tracker, :debug, :dry_run, :locale

  # @param stat_tracker StatTracker
  def initialize(stat_tracker, current_version)
    begin
      @version = current_version
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

  def greet
    puts I18n.t(:'menu.main.hello').light_green

    print "#{I18n.t(:'menu.main.version_info', version: @version)} - ".light_blue
    check_update(@version)
    puts separator

    print "#{I18n.t(:'menu.main.exit_shortcut_notice')} ".light_blue
    puts I18n.t(:'menu.main.exit_shortcut').light_white + '.'.light_blue
    puts "\n#{I18n.t(:'menu.main.confirm_banner_intro')}".light_blue
    puts "#{I18n.t(:'common.confirm_banner')}: #{I18n.t(:'menu.main.confirm_banner_example')} [y|n]".light_magenta

    puts separator
  end

  def check_summoner
    summoner = req_get_current_summoner
    if summoner['gameName'].nil? || summoner['gameName'].empty?
      puts I18n.t(:'menu.main.summoner_check_failed').light_red
      ask exit_string
      exit 1
    end

    puts "\n#{I18n.t(:'menu.main.logged_in_as', name: summoner['gameName'], tagline: summoner['tagLine'])}".light_blue
    puts separator
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
    puts I18n.t(:'menu.debug.post_request_info', path: "#{host}/#{path}").light_black if @debug
    puts I18n.t(:'menu.debug.dry_run.notice').light_red if @dry_run
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
    puts I18n.t(:'menu.debug.file_written_notice', filename: 'disenchanter_post.json')
  end
end
# rubocop:enable Metrics/ClassLength
