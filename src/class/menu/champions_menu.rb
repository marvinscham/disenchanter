# frozen_string_literal: true

require_relative 'menu'

require_relative '../../modules/handlers/champions_collection'
require_relative '../../modules/handlers/champions_exclusions'
require_relative '../../modules/handlers/champions_mastery'
require_relative '../../modules/handlers/champions_owned'
require_relative '../../modules/handlers/champions_tokens'

# Menu to select and call filtering options
class ChampionsMenu < Menu
  attr_reader :loot_shards

  def initialize(client, loot_shards)
    menu_text = 'Okay, which option would you like to go by?'
    things_todo = {
      '1' => 'Disenchant all champion shards',
      '2' => 'Keep enough (1/2) shards for champions you own mastery 6/7 tokens for',
      '3' => 'Keep enough (1/2) shards to fully master champions at least at mastery level x (select from 1 to 6)',
      '4' => 'Keep enough (1/2) shards to fully master all champions ' \
             '(only disenchant shards that have no possible use)',
      '5' => 'Keep one shard of each champion regardless of mastery',
      'x' => 'Back to main menu'
    }
    answer_display = 'Option'

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
      @loot_shards = handle_champions_tokens(@client, @loot_shards)
    when '3'
      @loot_shards = handle_champions_mastery(@client, @loot_shards)
    when '4'
      @loot_shards = handle_champions_mastery(@client, @loot_shards, keep_all: true)
    when '5'
      @loot_shards = handle_champions_collection(@loot_shards)
    end

    @loot_shards = @loot_shards.select { |l| l['count'].positive? }
    @loot_shards = @loot_shards.sort_by { |l| [l['disenchant_note'], l['itemDesc']] }

    true
  end
end
