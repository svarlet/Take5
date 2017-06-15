defmodule Game.PlayerTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper
  import Game.Model, only: [deck: 0]

  alias Game.Player

  test "a player requires a name to exist" do
    assert_raise FunctionClauseError, fn -> Player.new("") end
    assert_raise FunctionClauseError, fn -> Player.new(nil) end
  end

  property "create a player with new/1" do
    forall name <- player_name_gen() do
      %Player{name: name, hand: []} == Player.new(name)
    end
  end

  property "create a player with new/2" do
    forall {name, hand} <- {player_name_gen(), hand_gen(10)} do
      %Player{name: name, hand: hand} == Player.new(name, hand)
    end
  end

  property "starts with an empty hand" do
    forall name <- player_name_gen() do
      [] == Player.new(name).hand
    end
  end

  property "starts with no selected card" do
    forall player <- player_gen() do
      assert player.selected == :none
    end
  end

  property "has_card? returns false when the player's hand doesn't contain the specified card" do
    forall player <- player_gen() do
      deck = MapSet.difference(deck(), MapSet.new(player.hand))
      card_from_deck = Enum.random(deck)
      not Player.has_card?(player, card_from_deck)
    end
  end

  property "has_card? returns true when the player's hand contains the specified card" do
    forall player <- player_gen(cards: [at_least: 1]) do
      assert Player.has_card?(player, Enum.random(player.hand))
    end
  end

  property "attempt to select a card not in hand returns an error" do
    forall player <- player_gen() do
      a_card = [player.hand]
      |> remaining_deck
      |> Enum.random
      {:error, :card_not_in_hand} == Player.select(player, a_card)
    end
  end

  property "selecting a card from a player's hand references it in the selected field" do
    forall player <- player_gen(cards: [at_least: 1]) do
      a_card = Enum.random(player.hand)
      {:ok, %Player{selected: selection}} = Player.select(player, a_card)
      a_card == selection
    end
  end

  property "selecting a card from a player's hand removes it from his hand" do
    forall player <- player_gen(cards: [at_least: 1]) do
      a_card = Enum.random(player.hand)
      {:ok, %Player{hand: hand}} = Player.select(player, a_card)
      not Enum.member?(hand, a_card)
    end
  end

  property "selecting a second card returns an error" do
    forall player <- player_gen(cards: [at_least: 2]) do
      [card1, card2 | _] = Enum.shuffle(player.hand)
      {:ok, player} = Player.select(player, card1)
      {:error, :already_picked_a_card} == Player.select(player, card2)
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
