# frozen_string_literal: true

require_relative '../../class/dictionary'

# Combines key fragments to keys
# @param client Client connector
def handle_key_fragments(client)
  player_loot = client.req_get_player_loot

  loot_keys =
    player_loot.select { |l| l['lootId'] == Dictionary::KEY_FRAGMENT }
  fragment_count = count_loot_items(loot_keys)
  key_count = (count_loot_items(loot_keys) / 3).floor

  if fragment_count < 3
    puts I18n.t(:'handler.key_fragments.not_enough_fragments').yellow
    return
  end

  puts I18n.t(:'handler.key_fragments.found_fragments', count: fragment_count).light_blue
  if ans_y.include? user_input_check(
    I18n.t(:'handler.key_fragments.ask_craft_keys', key_count:, fragment_count:),
    ans_yn,
    ans_yn_d,
    'confirm'
  )
    client.stat_tracker.add_crafted(key_count)
    client.req_post_recipe(
      Dictionary::KEY_RECIPE,
      Dictionary::KEY_FRAGMENT,
      key_count
    )
    puts I18n.t(:'common.done').green
  end
rescue StandardError => e
  handle_exception(e, I18n.t(:'loot.key_fragments'))
end