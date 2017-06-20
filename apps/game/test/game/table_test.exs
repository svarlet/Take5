defmodule Game.TableTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  alias Game.Table

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
    cards = draw_cards(4)
    [c0, c1, c2, c3] = cards
    table = Table.new
    |> Table.set(cards)
    assert table.row_0 == [c0]
    assert table.row_1 == [c1]
    assert table.row_2 == [c2]
    assert table.row_3 == [c3]
  end
end
