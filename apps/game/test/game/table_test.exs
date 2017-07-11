defmodule Game.TableTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  doctest Game.Table

  alias Game.{Card, Table}

  test "has 4 empty rows" do
    table = %Table{}
    assert table.row_0 == []
    assert table.row_1 == []
    assert table.row_2 == []
    assert table.row_3 == []
  end

  property "set table with 4 cards" do
    forall {[c0, c1, c2, c3], _deck} <- cards_gen(4) do
      %Table{row_0: [c0], row_1: [c1], row_2: [c2], row_3: [c3]} == Table.new(c0, c1, c2, c3)
    end
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

  property "row_heads_by/2 returns the list of heads matching the given predicate" do
    forall {pivot_card, table} <- card_and_table_gen() do
      table
      |> Table.row_heads_by(Card.smaller_than(pivot_card))
      |> Enum.all?(fn c -> c.rank < pivot_card.rank end)
    end
  end

  property "any_head?/2 returns true if any head satisfies the given predicate" do
    forall {pivot_card, table} <- card_and_table_gen() do
      predicate = Card.smaller_than(pivot_card)
      Table.any_head?(table, predicate) == (table |> Table.row_heads_by(predicate) |> Enum.count != 0)
    end
  end

  property "any_head?/2 returns false when no head satisfies the given predicate" do
    forall {table, _deck} <- table_gen() do
      predicate = fn _ -> false end
      Table.any_head?(table, predicate) == false
    end
  end

  property "returns {:error, :choose_row} when a card cannot be stacked on any row" do
    forall {[c1, c2, c3, c4, c5], _deck} <- cards_gen(5) do
      {:error, :choose_row} == Table.new(c2, c3, c4, c5)
      |> Table.put(c1)
    end
  end

  property "a card is put in only one row" do
    forall {[c1, c2, c3, c4, c5], _deck} <- cards_gen(5) do
      with table <- Table.new(c1, c2, c3, c4),
           {:ok, {table, []}} <- Table.put(table, c5),
             row_heads <- Table.row_heads_by(table, fn c -> c == c5 end) do
        1 == Enum.count(row_heads)
      else
        error -> IO.puts("Putting a card on the table failed. #{inspect error}")
      end
    end
  end

  property "a card is put in the row with the closest lower rank" do
    forall {[c1, c2, c3, c4, c5], _deck} <- cards_gen(5) do
      {:ok, {table, []}} = Table.new(c1, c2, c3, c4)
      |> Table.put(c5)

      [c5, c4] == table.row_3
    end
  end

  property "a card replaces a row when it is put in a row with 5 cards" do
    forall {cards, _deck} <- cards_gen(9) do
      {full_row, [card_to_play, c1, c2, c3]} = Enum.split(cards, 5)

      {:ok, {table, _}} = %Table{row_0: full_row, row_1: [c1], row_2: [c2], row_3: [c3]}
      |> Table.put(card_to_play)

      [card_to_play] == table.row_0
    end
  end

  property "when a card replaces a row because it's full then the row can be gathered by the owner of the card" do
    forall {cards, _deck} <- cards_gen(9) do
      {full_row, [card_to_play, c1, c2, c3]} = Enum.split(cards, 5)

      {:ok, {_table, gathered_cards}} = %Table{row_0: full_row, row_1: [c1], row_2: [c2], row_3: [c3]}
      |> Table.put(card_to_play)

      gathered_cards == full_row
    end
  end

end
