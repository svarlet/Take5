defmodule Game.ModelTest do
  use ExUnit.Case, async: true

  alias Game.Model
  alias Game.Model.Card

  defp create_model(_) do
    [model: %Model{}]
  end

  describe "cards" do
    test "are numbered" do
      assert Map.has_key?(%Card{}, :number)
    end

    test "have a penalty" do
      assert Map.has_key?(%Card{}, :penalty)
    end
  end

  describe "a model is initialized with" do
    setup [:create_model]

    test "a status set to :init", context do
      assert context.model.status == :init
    end

    test "0 players", context do
      assert Enum.count(context.model.players) == 0
    end

    test "an empty list of hands", context do
      assert context.model.hands == []
    end

    test "an empty table", context do
      assert context.model.table == []
    end

    test "a deck of 104 unique cards with penalties", context do
      assert Enum.count(context.model.deck) == 104

      number_for_penalties =
        context.model.deck
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

  describe "players registration" do
    test "a player cannot be removed if it doesn't participate to a game" do
      model = %Model{}
      {:error, {:not_participating, ^model}} = Model.remove_player(model, "player1")
    end

    test "a player who participates to a game can be removed" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.remove_player(model, "player1") do
        refute Model.has_player?(model, "player1")
      else
        _ -> flunk "Adding then removing a player failed."
      end
    end

    test "a player can only register once" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1") do
        assert Model.has_player?(model, "player1")
        assert {:error, {:already_participating, ^model}} = Model.add_player(model, "player1")
      else
        _ -> flunk("Could not register player1")
      end
    end

    test "Up to 10 players can participate to a game" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2"),
           {:ok, model} <- Model.add_player(model, "player3"),
           {:ok, model} <- Model.add_player(model, "player4"),
           {:ok, model} <- Model.add_player(model, "player5"),
           {:ok, model} <- Model.add_player(model, "player6"),
           {:ok, model} <- Model.add_player(model, "player7"),
           {:ok, model} <- Model.add_player(model, "player8"),
           {:ok, model} <- Model.add_player(model, "player9"),
           {:ok, model} <- Model.add_player(model, "player10") do
        for i <- 1..10 do
          assert Model.has_player?(model, "player#{i}")
        end
        assert {:error, {:at_capacity, ^model}} = Model.add_player(model, "player11")
      else
        _ -> flunk "Registration of 10 users failed."
      end
    end
  end

  describe "Starting a game" do
    test "fails when there are fewer than 2 participants" do
      model = %Model{}
      assert {:error, {:not_enough_players, ^model}} = Model.start(model)

      {:ok, model} = Model.add_player(model, "player1")
      assert {:error, {:not_enough_players, ^model}} = Model.start(model)
    end

    test "update `status` when there are 2+ participants" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2") do
        assert {:ok, model} = Model.start(model)
        assert model.status == :started
      end
    end
  end

end
