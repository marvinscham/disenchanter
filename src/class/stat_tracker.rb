# frozen_string_literal: true

# Tracks usage stats for later optional submission
class StatTracker
  def initialize
    @actions = 0
    @blue_essence = 0
    @orange_essence = 0
    @disenchanted = 0
    @crafted = 0
    @redeemed = 0
    @opened = 0
  end

  attr_reader :actions, :blue_essence, :orange_essence, :disenchanted, :crafted, :redeemed, :opened

  def add_blue_essence(count)
    @blue_essence += count
  end

  def add_orange_essence(count)
    @orange_essence += count
  end

  def add_disenchanted(count)
    @disenchanted += count
  end

  def add_actions(count)
    @actions += count
  end

  def add_crafted(count)
    @crafted += count
  end

  def add_redeemed(count)
    @redeemed += count
  end

  def add_opened(count)
    @opened += count
  end
end
