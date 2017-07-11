defmodule Game.DeckTest do
  use ExUnit.Case, async: true

  alias Game.Deck

  doctest Game.Deck

  test "a new deck has 104 cards" do
    assert 104 == Enum.count(Deck.deck())
  end

  test "a new deck has all heads from 1 to 104" do
    assert Enum.to_list(1..104) == Deck.deck()
    |> Enum.map(fn c -> c.rank end)
    |> Enum.sort
  end


end
