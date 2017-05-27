defmodule Game.ModelTest do
  use ExUnit.Case, async: true

  alias Game.Model

  defp create_model(_) do
    [model: %Model{}]
  end

  describe "a model is initialized with" do
    setup [:create_model]

    test "a status set to :init", context do
      assert context.model.status == :init
    end

    test "0 players", context do
      assert Model.count_players(context.model) == 0
    end

    test "an empty map of hands", context do
      assert context.model.hands == %{}
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

    test "a player cannot be removed once the game has started" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player 1"),
           {:ok, model} <- Model.add_player(model, "player 2"),
           {:ok, model} <- Model.start(model) do
        assert {:error, {:not_permitted_in_game, ^model}} = Model.remove_player(model, "player 1")
      else
        error -> flunk "Game could not start. (reason: #{inspect error})"
      end
    end

    test "a player who participates to a game can be removed" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.remove_player(model, "player1") do
        refute Model.has_player?(model, "player1")
      else
        error -> flunk "Adding then removing a player failed. (reason: #{inspect error})"
      end
    end

    test "a player can only register once" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1") do
        assert Model.has_player?(model, "player1")
        assert {:error, {:already_participating, ^model}} = Model.add_player(model, "player1")
      else
        error -> flunk("Could not register player1. (reason: #{inspect error})")
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
        error -> flunk "Registration of 10 users failed. (reason: #{inspect error})"
      end
    end

    test "fails when game has already started" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2"),
           {:ok, model} <- Model.start(model) do
        assert {:error, {:game_has_already_started, ^model}} = Model.add_player(model, "player3")
      else
        error -> flunk "Failed to start the game. (reason: #{inspect error})"
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

    test "update `status` if there are 2+ participants" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2") do
        assert {:ok, model} = Model.start(model)
        assert Model.started?(model)
      else
        error -> flunk "Could not start the game successfully. (reason: #{inspect error})"
      end
    end
  end

  describe "Dealing the cards" do
    test "fails when game is not started" do
      model = %Model{}
      assert {:error, {:not_started, ^model}} = Model.deal(model)
    end

    test "deals 10 cards to each player" do
      with model = %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2"),
           {:ok, model} <- Model.start(model) do
        {:ok, %Model{hands: all_hands}} = Model.deal(model)
        assert Enum.count(all_hands) == 2
        assert Enum.all?(all_hands, fn {_player, hand} -> Enum.count(hand) == 10 end)
      else
        error -> flunk "Game could not start. (reason: #{inspect error})"
      end
    end

    test "deals distinct cards" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2"),
           {:ok, model} <- Model.start(model),
           {:ok, model} <- Model.deal(model) do
        dealt_cards = model.hands
        |> Enum.flat_map(fn {_player, hand} -> hand end)
        |> Enum.uniq
        assert Enum.count(dealt_cards) == 20
      else
        error -> flunk "Dealing the cards failed. (reason: #{inspect error})"
      end
    end

    test "should provide different hands in different games" do
      with model <- %Model{},
           {:ok, model} <- Model.add_player(model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2"),
           {:ok, model} <- Model.start(model) do
        {:ok, %Model{hands: hands_A}} = Model.deal(model)
        {:ok, %Model{hands: hands_B}} = Model.deal(model)
        assert hands_A != hands_B
      else
        error -> flunk "Game did not start successfully. (reason: #{inspect error})"
      end
    end
  end
end
