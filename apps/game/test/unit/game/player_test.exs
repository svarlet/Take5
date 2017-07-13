defmodule Game.PlayerTest do
  use ExUnit.Case, async: true
  use PropCheck
  use Exceptional

  import TestHelper
  import Game.Deck, only: [deck: 0]
  import Game.Card, only: [card: 1]

  doctest Game.Player

  alias Game.Player
  alias Game.Player.CardNotOwnedError

  property "Creating a player with an empty name is invalid", [:verbose] do
    forall hand <- hand_gen() do
      match? %Player.InvalidPlayerNameError{}, Player.new("", hand)
    end
  end

  property "Creating a player with a nil list of cards is invalid" do
    forall name <- binary(5) do
      implies name != "" do
        match? %Player.InvalidHandError{}, Player.new(name, nil)
      end
    end
  end

  property "create a player with new/2" do
    forall {name, hand} <- {player_name_gen(), hand_gen(10)} do
      %Player{name: name, hand: hand} == Player.new(name, hand)
    end
  end

  property "starts with no selected card" do
    forall player <- player_gen() do
      assert player.selected == :none
    end
  end

  property "has_card? returns false when the player's hand doesn't contain the specified card" do
    forall player <- player_gen() do
      deck = deck() -- player.hand
      card_from_deck = Enum.random(deck)
      not Player.has_card?(player, card_from_deck)
    end
  end

  property "has_card? returns true when the player's hand contains the specified card" do
    forall player <- player_gen(cards: [at_least: 1]) do
      assert Player.has_card?(player, Enum.random(player.hand))
    end
  end

  property "attempt to select a card not in hand returns an error", [:verbose] do
    forall player <- player_gen() do
      cards_not_owned = Enum.to_list(1..104) -- Enum.map(player.hand, fn c -> c.rank end)
      forall rank <- elements(cards_not_owned) do
        match? %CardNotOwnedError{}, Player.select(player, card(rank))
      end
    end
  end

  property "selecting a card from a player's hand references it in the selected field", [:verbose] do
    forall player <- player_gen(cards: [at_least: 1]) do
      a_card = Enum.random(player.hand)
      %Player{selected: selection} = Player.select(player, a_card)
      a_card == selection
    end
  end

  property "selecting a card from a player's hand removes it from his hand" do
    forall player <- player_gen(cards: [at_least: 1]) do
      a_card = Enum.random(player.hand)
      %Player{hand: hand} = Player.select(player, a_card)
      not Enum.member?(hand, a_card)
    end
  end

  property "changing the selected card places it back in hand" do
    forall player <- player_gen(cards: [at_least: 2]) do
      [card1, card2 | _] = player.hand
      player
      |> Player.select(card1)
      ~> Player.select(card2)
      ~> Player.has_card?(card1)
    end
  end

  property "no_selection? returns true when the player hasn't selected any card" do
    forall player <- player_gen() do
      Player.no_selection?(player) == true
    end
  end

  property "no_selection? returns false when the player has selected a card" do
    forall player <- player_gen(cards: [at_least: 1]) do
      [a_card | _] = player.hand
      false == player
      |> Player.select(a_card)
      |> Player.no_selection?
    end
  end

end
