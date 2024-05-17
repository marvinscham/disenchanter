# frozen_string_literal: true

require_relative '../../class/dictionary'

# Combines key fragments to keys
# @param client Client connector
# @param accept Auto-accept level
def handle_key_fragments(client, accept = 0)
  player_loot = client.req_get_player_loot

  loot_keys =
    player_loot.select { |l| l['lootId'] == Dictionary::KEY_FRAGMENT }
  fragment_count = count_loot_items(loot_keys)
  key_count = (fragment_count / 3).floor

  if fragment_count < 3
    puts I18n.t(:'handler.key_fragments.not_enough_fragments').yellow
    return
  end

  puts I18n.t(:'handler.key_fragments.found_fragments', count: fragment_count).light_blue
  if accept >= 1 || ans_y.include?(user_input_check(
    I18n.t(:'handler.key_fragments.ask_craft_keys', key_count:, fragment_count:),
    ans_yn,
    ans_yn_d,
    'confirm'
  ))
    client.stat_tracker.add_crafted(key_count)
    client.req_post_recipe(
      Dictionary::KEY_RECIPE,
      Dictionary::KEY_FRAGMENT,
      key_count
    )
    puts I18n.t(:'common.done').green
  end
rescue StandardError => e
  handle_exception(e, 'key fragments')
end
