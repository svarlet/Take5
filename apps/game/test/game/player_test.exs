defmodule Game.PlayerTest do
  use ExUnit.Case, async: true
  use Quixir

  import TestHelper
  alias Game.Player

  test "a player requires a name to exist" do
    assert_raise FunctionClauseError, fn -> Player.new("") end
    assert_raise FunctionClauseError, fn -> Player.new(nil) end
  end

  test "create a player with new/1" do
    ptest name: string(min: 1) do
      Player.new(name)
    end
  end

  test "create a player with new/2" do
    ptest hand_size: int(min: 0, max: 10) do
      Player.new("John", random_hand(hand_size))
    end
  end

  defp random_hand(size) do
    deck()
    |> Enum.shuffle
    |> Enum.take(size)
  end

  test "starts with an empty hand" do
    ptest name: string(min: 1) do
      assert Player.new(name).hand == []
    end
  end

  test "starts with no selected card" do
    ptest name: string(min: 1) do
      assert Player.new(name).selected == :none
    end
  end

  test "has_card? returns false when the player's hand doesn't contain the specified card" do
    ptest hand_size: int(min: 0, max: 10) do
      {hand, deck} = random_hand_and_deck(hand_size)
      p = Player.new("Maria", hand)
      refute Player.has_card?(p, Enum.random(deck))
    end
  end

  defp random_hand_and_deck(size) do
    deck()
    |> Enum.shuffle
    |> Enum.split(size)
  end

  test "has_card? returns true when the player's hand contains the specified card" do
    ptest hand_size: int(min: 1, max: 10) do
      hand = random_hand(hand_size)
      p = Player.new("Martin", hand)
      assert Player.has_card?(p, Enum.random(hand))
    end
  end

  test "attempt to select a card not in hand returns an error" do
    ptest hand_size: int(min: 0, max: 10) do
      {hand, deck} = random_hand_and_deck(hand_size)
      p = Player.new("Julie", hand)
      assert {:error, :card_not_in_hand} == Player.select(p, Enum.random(deck))
    end
  end

  test "selecting a card from a player's hand references it in the selected field" do
    ptest hand_size: int(min: 1, max: 10) do
      hand = random_hand(hand_size)
      p = Player.new("Arthur", hand)
      one_of_his_card = Enum.random(p.hand)
      assert {:ok, %Player{selected: ^one_of_his_card}} = Player.select(p, one_of_his_card)
    end
  end

  test "selecting a card from a player's hand removes it from his hand" do
    ptest hand_size: int(min: 1, max: 10) do
      hand = random_hand(hand_size)
      p = Player.new("Arthur", hand)
      one_of_his_card = Enum.random(p.hand)
      assert {:ok, p_updated} = Player.select(p, one_of_his_card)
      refute Player.has_card?(p_updated, one_of_his_card)
    end
  end

  test "selecting a second card returns an error" do
    ptest hand_size: int(min: 2, max: 10) do
      [c1, c2 | _] = hand = random_hand(hand_size)
      {:ok, p} = "George"
      |> Player.new(hand)
      |> Player.select(c1)
      assert {:error, :already_picked_a_card} == Player.select(p, c2)
    end
  end

end
