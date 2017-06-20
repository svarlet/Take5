defmodule Game.ModelTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  alias Game.{Model, Card, Player, Table}

  defp create_model(_) do
    [model: %Model{}]
  end

  defp add_players(model, quantity) when quantity in 1..10 do
    1..quantity
    |> Enum.map(& "player #{&1}")
    |> Enum.reduce(model, fn p, m -> m |> Model.add_player(p) |> elem(1) end)
  end

  describe "a model is initialized with" do
    setup [:create_model]

    test "a status set to :init", context do
      assert context.model.status == :init
    end

    test "0 players", context do
      assert Model.count_players(context.model) == 0
    end

    test "an empty table", context do
      assert context.model.table == Table.new
    end

    test "a deck of 104 unique cards with penalties", context do
      assert Enum.count(context.model.deck) == 104

      number_for_penalties =
        context.model.deck
        |> Enum.group_by(fn card -> card.penalty end, fn card -> card.head end)

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
    setup [:create_model]

    test "a player cannot be removed if it doesn't participate to a game", %{model: model} do
      {:error, :not_participating} = Model.remove_player(model, "player1")
    end

    test "a player can be removed once the game has started", context do
      with model2 <- add_players(context.model, 2),
           {:ok, model3} <- Model.add_player(model2, "player 3"),
           {:ok, model3} <- Model.start(model3) do
        {:ok, model2} = Model.remove_player(model3, "player 3")
        assert model2.players["player 1"] == model3.players["player 1"]
        assert model2.players["player 2"] == model3.players["player 2"]
      else
        error -> flunk "Game could not start. (reason: #{inspect error})"
      end
    end

    test "a player who participates to a game can be removed", context do
      with {:ok, model} <- Model.add_player(context.model, "player1"),
           {:ok, model} <- Model.remove_player(model, "player1") do
        refute Model.has_player?(model, "player1")
      else
        error -> flunk "Adding then removing a player failed. (reason: #{inspect error})"
      end
    end

    test "a player can only register once", context do
      with {:ok, model} <- Model.add_player(context.model, "player1") do
        assert Model.has_player?(model, "player1")
        assert {:error, :already_participating} = Model.add_player(model, "player1")
      else
        error -> flunk("Could not register player1. (reason: #{inspect error})")
      end
    end

    test "Up to 10 players can participate to a game", context do
      model = add_players(context.model, 10)
      for i <- 1..10 do
        assert Model.has_player?(model, "player #{i}")
      end
      assert {:error, :at_capacity} = Model.add_player(model, "player11")
    end

    test "fails when game has already started", context do
      with model <- add_players(context.model, 2),
           {:ok, model} <- Model.start(model) do
        assert {:error, :game_has_already_started} = Model.add_player(model, "player3")
      else
        error -> flunk "Failed to start the game. (reason: #{inspect error})"
      end
    end
  end

  describe "Starting a game" do
    setup [:create_model]

    test "fails when there are fewer than 2 participants", %{model: model} do
      assert {:error, :not_enough_players} = Model.start(model)

      {:ok, model1} = Model.add_player(model, "player1")
      assert {:error, :not_enough_players} = Model.start(model1)
    end

    test "update `status` if there are 2+ participants", context do
      with {:ok, model} <- Model.add_player(context.model, "player1"),
           {:ok, model} <- Model.add_player(model, "player2"),
           {:ok, model} <- Model.start(model) do
        assert Model.started?(model)
      else
        error -> flunk "Could not start the game successfully. (reason: #{inspect error})"
      end
    end

    test "deals 10 cards to each player", context do
      with model <- add_players(context.model, 2),
           {:ok, %Model{players: players}} <- Model.start(model),
             all_hands <- Enum.map(players, fn {_name, player} -> player.hand end) do
        assert Enum.count(all_hands) == 2
        assert Enum.all?(all_hands, fn hand -> Enum.count(hand) == 10 end)
      else
        error -> flunk "Game could not start. (reason: #{inspect error})"
      end
    end

    test "deals distinct cards", context do
      with model <- add_players(context.model, 2),
           {:ok, model} <- Model.start(model) do
        dealt_cards = model.players
        |> Enum.flat_map(fn {_player_name, state} -> state.hand end)
        |> Enum.uniq
        assert Enum.count(dealt_cards) == 20
      else
        error -> flunk "Dealing the cards failed. (reason: #{inspect error})"
      end
    end

    test "should provide different hands in different games", context do
      with model <- add_players(context.model, 2),
           {:ok, %Model{players: players_a}} <- Model.start(model),
           {:ok, %Model{players: players_b}} <- Model.start(model) do
        assert Map.values(players_a) != Map.values(players_b)
      else
        error -> flunk "Game did not start successfully. (reason: #{inspect error})"
      end
    end

    test "does not select a card to play on behalf of the player", context do
      with model <- add_players(context.model, 2),
           {:ok, %Model{players: players}} <- Model.start(model),
             all_players <- Map.values(players),
             all_selected_cards <- Enum.map(all_players, fn p -> p.selected end) do
        assert Enum.all?(all_selected_cards, &(&1 == :none))
      else
        error -> flunk "Game could not start. (reason: #{inspect error})"
      end
    end

    test "arrange 4 different cards on the table", context do
      with model <- add_players(context.model, 2),
           {:ok, %Model{table: table}} <- Model.start(model) do
        %{0 => [card_0], 1 => [card_1], 2 => [card_2], 3 => [card_3]} = table
        table_cards = [card_0, card_1, card_2, card_3]
        assert Enum.uniq(table_cards) == table_cards
        assert Enum.all?([card_0, card_1, card_2, card_3], &is_card?/1)
      else
        error -> flunk "Could not start a regular game with 2 players. (reason: #{inspect error})"
      end
    end

    defp is_card?(%Card{}), do: true
    defp is_card?(_), do: false
  end

  describe "In game" do
    setup [:create_model]

    test "playing a card before the game starts returns an error", context do
      result = context.model
      |> add_players(2)
      |> Model.select("player 1", {1, 1})
      assert {:error, :game_not_started} == result
    end

    test "playing a card with an invalid player returns an error", context do
      with model <- add_players(context.model, 2),
           {:ok, model} <- Model.start(model) do
        assert {:error, :not_playing} == Model.select(model, "not a player", {1, 1})
      else
        error -> flunk "Could not initialize the game. (reason: #{inspect error})"
      end
    end

    test "playing a card that the player doesn't own returns an error", context do
      with model <- add_players(context.model, 2),
           {:ok, model} <- Model.start(model) do
        assert {:error, :card_not_in_hand} == Model.select(model, "player 1", Enum.take(model.deck, 1))
      else
        error -> flunk "Could not initialize the game. (reason: #{inspect error})"
      end
    end

    test "playing 2 cards for the same player returns an error", context do
      with model <- add_players(context.model, 2),
           {:ok, model} <- Model.start(model),
             %Player{hand: [card1, card2 | _]} <- model.players["player 1"],
           {:ok, model} <- Model.select(model, "player 1", card1) do
        assert {:error, :already_picked_a_card} == Model.select(model, "player 1", card2)
      else
        error -> flunk "Could not setup the game and select one card for player 1. (reason: #{inspect error})"
      end
    end

    test "process_round/1 returns an error if the game has not started", context do
      assert {:error, :game_not_started} == context.model
      |> add_players(2)
      |> Model.process_round()
    end

    property "process_round returns an error if any player hasn't selected a card", [:quiet], _context do
      forall model <- model_gen() do
        {:error, :missing_selection} == model
        |> select_cards(players: :all_but_one)
        |> Model.process_round
      end
    end

    property "when all players have selected a card, process_round succeeds", [:quiet], _context do
      forall model <- model_gen() do
        result = model
        |> select_cards(players: :all)
        |> Model.process_round
        match?({:ok, _}, result)
      end
    end

  end
end
