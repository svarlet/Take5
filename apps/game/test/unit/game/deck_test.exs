defmodule Game.DeckTest do
  use ExUnit.Case, async: true
  use PropCheck

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

  property "deal(deck, n) returns n cards and an updated deck" do
    forall n <- integer(0, 104) do
      deck = Deck.deck()
      {cards, updated_deck} = Deck.deal(deck, n)
      cards ++ updated_deck == deck
    end
  end


end
