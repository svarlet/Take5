defmodule Game.ModelTest do
  use ExUnit.Case, async: true

  alias Game.Model
  alias Game.Model.Card

  describe "cards" do
    test "are numbered" do
      assert Map.has_key?(%Card{}, :number)
    end

    test "have a penalty" do
      assert Map.has_key?(%Card{}, :penalty)
    end
  end

  describe "a model is initialized with" do
    test "an empty list of players" do
      model = %Model{}
      assert model.players == []
    end

    test "an empty list of hands" do
      model = %Model{}
      assert model.hands == []
    end

    test "an empty table" do
      model = %Model{}
      assert model.table == []
    end

    test "a deck of 104 unique cards with penalties" do
      model = %Model{}
      assert Enum.count(model.deck) == 104

      number_for_penalties =
        model.deck
        |> Enum.group_by(fn {_, penalty} -> penalty end, fn {number, _} -> number end)

      penalty_of = fn penalty ->
        number_for_penalties
        |> Map.get(penalty)
        |> Enum.sort
      end

      assert penalty_of.(7) == [55]
      assert penalty_of.(5) == [11, 22, 33, 44, 66, 77, 88, 99]
      assert penalty_of.(3) == [10, 20 , 30 , 40 , 50 , 60, 70, 80, 90, 100]
      assert penalty_of.(2) == [5, 15, 25, 35, 45, 65, 75, 85, 95]
      assert penalty_of.(1) == [1, 2, 3, 4, 6, 7, 8, 9, 12, 13, 14, 16, 17, 18, 19, 21, 23, 24, 26, 27, 28, 29,
                                31, 32, 34, 36, 37, 38, 39, 41, 42, 43, 46, 47, 48, 49, 51, 52, 53, 54, 56, 57,
                                58, 59, 61, 62, 63, 64, 67, 68, 69, 71, 72, 73, 74, 76, 78, 79, 81, 82, 83, 84, 86, 87,
                                89, 91, 92, 93, 94, 96, 97, 98, 101, 102, 103, 104]
    end

  end
end
