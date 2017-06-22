defmodule GameTest do
  use ExUnit.Case, async: true
  doctest Game.Model
  doctest Game.Card
  doctest Game.Player
  doctest Game.Table
end
