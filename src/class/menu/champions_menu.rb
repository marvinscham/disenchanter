# frozen_string_literal: true

require_relative 'menu'

require_relative '../../modules/handlers/champions_collection'
require_relative '../../modules/handlers/champions_exclusions'
require_relative '../../modules/handlers/champions_owned'

# Menu to select and call filtering options
class ChampionsMenu < Menu
  attr_reader :loot_shards

  def initialize(client, loot_shards)
    menu_text = I18n.t(:'menu.choose_option')
    things_todo = {
      '1' => I18n.t(:'menu.champions.options.all'),
      '2' => I18n.t(:'menu.champions.options.collector'),
      'x' => I18n.t(:'menu.back_to_detail')
    }
    answer_display = I18n.t(:'menu.option')

    super(client, menu_text, answer_display, things_todo)
    @loot_shards = loot_shards
  end

  # Calls the corresponding champion shard handling method
  # @param thing_todo Option name
  # @return true if done
  def handle_option(thing_todo)
    case thing_todo
    when '1', 'x'
      # no filtering needed -> done
    when '2'
      @loot_shards = handle_champions_collection(@loot_shards)
    else
      return false
    end

    @loot_shards = @loot_shards.select { |l| l['count'].positive? }
    @loot_shards = @loot_shards.sort_by { |l| [l['disenchant_note'], l['itemDesc']] }

    true
  end
end
