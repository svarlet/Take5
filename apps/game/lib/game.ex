defmodule Game do

  alias Game.Player

  def new(player_names) when length(player_names) in 2..10 do
    Enum.map(player_names, &Player.new/1)
  end

  def players(game) do
    game
  end
end
