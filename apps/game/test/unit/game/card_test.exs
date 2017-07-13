defmodule Game.CardTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  doctest Game.Card

  alias Game.Card

  property "cards/1 creates a list of cards for the provided list of ranks" do
    forall ranks <- list(integer(1, 104)) do
      ranks == ranks
      |> Card.cards()
      |> Enum.map(fn c -> c.rank end)
    end
  end

  property "compare returns :lt | :eq | :gt if the first card is lower | equal | greater than the second card" do
    forall {lower_card, higher_card} <- pair_of_cards_gen() do
      Card.compare(lower_card, higher_card) == :lt
      && Card.compare(higher_card, lower_card) == :gt
      && Card.compare(lower_card, lower_card) == :eq
    end
  end

  property "smaller_than/2 returns true when a card is smaller than a reference card" do
    forall {low, high} <- pair_of_cards_gen() do
      Card.smaller_than(high, low) && !Card.smaller_than(low, high)
    end
  end

  property "closest_lower_card/2 returns nil when there is no such card2" do
    forall {[card | cards], _deck} <- cards_gen(5) do
      Card.closest_lower_card(card, cards) == nil
    end
  end

  property "closest_lower_card/2 finds the closest lower card." do
    forall {index, {five_cards, _deck}} <- {integer(1, 4), cards_gen(5)} do
      {card, cards} = List.pop_at(five_cards, index)
      Card.closest_lower_card(card, cards) == Enum.at(cards, index - 1)
    end
  end

end
