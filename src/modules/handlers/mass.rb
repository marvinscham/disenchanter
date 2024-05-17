# frozen_string_literal: true

require_relative '../../modules/handlers/key_fragments'
require_relative '../../modules/handlers/capsules'
require_relative '../../modules/handlers/champions'
require_relative '../../modules/handlers/skins'
require_relative '../../modules/handlers/icons'
require_relative '../../modules/handlers/tacticians'
require_relative '../../modules/handlers/wards'
require_relative '../../modules/handlers/emotes'
require_relative '../../modules/handlers/eternals'

# Opens all keyless chests then disenchants all loot the player already owns
# @param client Client connector
# @param accept Auto-accept level
def handle_mass(client, accept)
  return unless [1, 2].include?(accept)

  if accept == 1 &&
     ans_n.include?(user_input_check(
                      I18n.t('menu.mass.ask_run_soft'),
                      ans_yn, ans_yn_d, 'confirm'
                    ))
    return
  end

  if accept == 2 &&
     ans_n.include?(user_input_check(
                      I18n.t('menu.mass.ask_run_hard'),
                      %w[YES n], '[YES|n]', 'confirm'
                    ))
    return
  end

  handle_key_fragments(client, accept)
  handle_capsules(client, accept)
  handle_champions(client, accept)
  handle_skins(client, accept)
  handle_tacticians(client, accept)
  handle_eternals(client, accept)
  handle_emotes(client, accept)
  handle_ward_skins(client, accept)
  handle_icons(client, accept)

  puts I18n.t("menu.mass.all_steps_success").light_green
end
