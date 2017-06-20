defmodule Game.TableTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  alias Game.{Card, Table}

  test "create a table" do
    Table.new
  end

  test "has 4 empty rows" do
    table = Table.new
    assert table.row_0 == []
    assert table.row_1 == []
    assert table.row_2 == []
    assert table.row_3 == []
  end

  test "set table with 4 cards" do
    {cards, _deck} = draw_cards(4)
    [c0, c1, c2, c3] = cards
    table = Table.new
    |> Table.set(cards)
    assert table.row_0 == [c0]
    assert table.row_1 == [c1]
    assert table.row_2 == [c2]
    assert table.row_3 == [c3]
  end

  property "putting a card" do
    forall {table, deck} <- table_gen() do
      card_to_play = Enum.random(deck)

      IO.puts "Card to play: #{card_to_play}"

      closest_card = table
      |> Map.values
      |> Enum.map(List.first)
      |> Enum.filter(fn card -> Card.compare(card, card_to_play) == :lt end)
      |> Enum.max_by(fn card -> card.head end)

      assert table
      |> Table.put(card_to_play)
      |> Map.values
      |> Enum.any?(fn row -> row == [card_to_play | closest_card] end)
    end
  end
end
