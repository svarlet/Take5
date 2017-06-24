defmodule Game.CardTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  alias Game.Card

  property "cards/1 creates a list of cards for the provided list of heads" do
    forall heads <- list(integer(1, 104)) do
      heads == Enum.map(Card.cards(heads), fn c -> c.head end)
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
    forall some_cards <- vector(5, card_gen()) do
      {card, cards} = some_cards
      |> Enum.sort
      |> List.pop_at(0)
      Card.closest_lower_card(card, cards) == nil
    end
  end

  property "closest_lower_card/2 finds the closest lower card." do
    forall {index, five_cards} <- {integer(1, 4), vector(5, card_gen())} do
      implies 5 == five_cards |> Enum.uniq |> Enum.count do
        {card, cards} = five_cards
        |> Enum.sort_by(fn c -> c.head end)
        |> List.pop_at(index)
        Card.closest_lower_card(card, cards) == Enum.at(cards, index - 1)
      end
    end
  end

end
