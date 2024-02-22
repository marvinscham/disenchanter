# frozen_string_literal: true

# Holds constants for Loot IDs
class Dictionary
  BLUE_ESSENCE = 'CURRENCY_champion'
  ORANGE_ESSENCE = 'CURRENCY_cosmetic'
  MYTHIC_ESSENCE = 'CURRENCY_mythic'

  KEY_FRAGMENT = 'MATERIAL_key_fragment'
  MASTERY_TOKEN = 'CHAMPION_TOKEN'
  EMOTE = 'EMOTE'
  ICON = 'SUMMONERICON'
  TACTICIAN = 'COMPANION'

  CHAMPION_SHARD = 'CHAMPION_RENTAL'
  CHAMPION_PERMANENT = 'CHAMPION'

  SKIN_SHARD = 'SKIN_RENTAL'
  SKIN_PERMANENT = 'SKIN'

  WARD_SKIN_SHARD = 'WARDSKIN_RENTAL'
  WARD_SKIN_PERMANENT = 'WARDSKIN'

  ETERNAL_SHARD = 'STATSTONE_SHARD'
  ETERNAL_PERMANENT = 'STATSTONE'

  MASTERY_6_TOKEN = 'CHAMPION_TOKEN_6'
  MASTERY_7_TOKEN = 'CHAMPION_TOKEN_7'

  MASTERY_6_BASE_RECIPE = 'CHAMPION_TOKEN_6_redeem_with'
  MASTERY_7_BASE_RECIPE = 'CHAMPION_TOKEN_7_redeem_with'
  MASTERY_6_BE_RECIPE = "#{MASTERY_6_BASE_RECIPE}essence".freeze
  MASTERY_7_BE_RECIPE = "#{MASTERY_7_BASE_RECIPE}essence".freeze
  MASTERY_6_SHARD_RECIPE = "#{MASTERY_6_BASE_RECIPE}shard".freeze
  MASTERY_7_SHARD_RECIPE = "#{MASTERY_7_BASE_RECIPE}shard".freeze
  MASTERY_6_PERM_RECIPE = "#{MASTERY_6_BASE_RECIPE}permanent".freeze
  MASTERY_7_PERM_RECIPE = "#{MASTERY_7_BASE_RECIPE}permanent".freeze

  EMOTE_RE_ROLL_RECIPE = 'EMOTE_forge'
  KEY_RECIPE = 'MATERIAL_key_fragment_forge'

  RANDOM_SKIN_SHARD = 'CHEST_291'

  STATUS_OWNED = 'ALREADY OWNED'
end
