defmodule GameTest do
  use ExUnit.Case, async: true
  doctest Game.Deck
  doctest Game.Card
  doctest Game.Player
  doctest Game.Table
end
