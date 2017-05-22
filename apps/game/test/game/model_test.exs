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

    test "a deck of 104 cards" do
      model = %Model{}
      assert length(model.deck) == 104
    end
  end
end
