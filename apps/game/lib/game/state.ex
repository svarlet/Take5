defmodule Game.State do
  @moduledoc false
  @callback join(game :: Game.t, name :: String.t) :: Game.t | Exception.t
  @callback start(game :: Game.t) :: Game.t | Exception.t
  @callback select(game :: Game.t, name :: String.t, card :: Card.t) :: Game.t | Exception.t
  @callback play_round(game :: Game.t) :: Game.t | Exception.t
  @callback choose_row(game :: Game.t, name :: String.t, row_id :: :r1 | :r2 | :r3 | :r4) :: Game.t
end
