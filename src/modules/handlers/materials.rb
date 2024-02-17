# frozen_string_literal: true

require_relative '../../class/menu/materials_menu'

# Wrapper for materials
# @param client Client connector
def handle_materials(client)
  MaterialsMenu.new(client).run_loop
end
