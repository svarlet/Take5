defmodule Game.ModelTest do
  use ExUnit.Case, async: true

  alias Game.Model

  describe "model defaults" do
    test "a model is initialized with an empty list of players" do
      model = %Model{}
      assert model.players == []
    end

  end
end
