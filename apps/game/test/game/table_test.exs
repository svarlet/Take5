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

  property "rows/1 returns the 4 rows of cards" do
    forall {table, _deck} <- table_gen() do
      [table.row_0, table.row_1, table.row_2, table.row_3] == Table.rows(table)
    end
  end

  property "row_heads/1 returns a list of the last card put in each row" do
    forall {table, _deck} <- table_gen() do
      Table.row_heads(table) == table
      |> Map.take(~w(row_0 row_1 row_2 row_3)a)
      |> Map.values
      |> Enum.map(&List.first/1)
    end
  end

  property "putting a card higher than at least one of the table cards" do
    table_and_card_gen =
      let {table, deck} <- table_gen() do
        deck_cards = MapSet.to_list(deck)
        higher_card_gen = such_that card <- oneof(deck_cards), when: Enum.any?(Table.row_heads(table), Card.smaller_than(card))
        let card <- higher_card_gen do
          {card, table}
        end
      end

    forall {card_to_play, table} <- table_and_card_gen do
      row_heads = Table.row_heads(table)

      closest_card = row_heads
      |> Enum.filter(fn card -> Card.compare(card, card_to_play) == :lt end)
      |> Enum.max_by(fn card -> card.head end)

      final_rows = table
      |> Table.put(card_to_play)
      |> Table.rows

      1 == final_rows
      |> Enum.filter(fn row -> match?([^card_to_play, ^closest_card | _], row) end)
      |> Enum.count
    end
  end

end
