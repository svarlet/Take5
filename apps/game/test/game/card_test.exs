defmodule Game.CardTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  alias Game.Card

  property "compare returns :lt | :eq | :gt if the first card is lower | equal | greater than the second card" do
    forall {lower_card, higher_card} <- pair_of_cards_gen() do
      Card.compare(lower_card, higher_card) == :lt
      && Card.compare(higher_card, lower_card) == :gt
      && Card.compare(lower_card, lower_card) == :eq
    end
  end
end
