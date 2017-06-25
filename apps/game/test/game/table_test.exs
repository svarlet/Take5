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

  property "a card is put in only one row" do
    forall {card, table} <- card_and_table_gen() do
      closest = Card.closest_lower_card(card, Table.row_heads(table))
      implies closest != nil do
        1 == table
        |> Table.put(card)
        |> Table.row_heads
        |> Enum.filter(fn c -> c == card end)
        |> Enum.count
      end
    end
  end

  property "a card is put in the row with the closest lower head" do
    forall {card, table} <- card_and_table_gen() do
      closest = Card.closest_lower_card(card, Table.row_heads(table))
      implies closest != nil do
        table
        |> Table.put(card)
        |> Table.rows
        |> Enum.any?(fn r -> Enum.take(r, 2) == [card, closest] end)
      end
    end
  end

  property "a card replaces a row when it is put in a row with 5 cards" do
    forall {card, table} <- card_and_table_gen() do
      implies Enum.any?(Table.rows(table), fn row -> Enum.count(row) == 5 end) do
        {row_id, row} = row_with_5_cards(table)
        implies hd(row) == Card.closest_lower_card(card, Table.row_heads(table)) do
          [card] == table
          |> Table.put(card)
          |> Map.get(row_id)
        end
      end
    end
  end

  defp row_with_5_cards(table) do
    table
    |> Map.take(~w(row_0 row_1 row_2 row_3)a)
    |> Enum.find(fn {_row_id, row} -> Enum.count(row) == 5 end)
  end

end
