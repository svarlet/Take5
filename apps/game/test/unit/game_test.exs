defmodule GameTest do
  use ExUnit.Case, async: true
  use PropCheck
  use Exceptional

  import TestHelper

  alias Game.{Table, Card}
  alias Game.{
    InvalidPlayerCountError,
    NonUniquePlayerNameError,
    NotPlayingError
  }

  import Card, only: [card: 1]

  #
  # TESTING PLAYERS REGISTRATION
  #

  property "a game cannot be created with less than 2 players or more than 10 players", [:verbose] do
    forall count <- union([integer(0, 1), integer(11, :inf)]) do
      forall names <- vector(count, binary(5)) do
        match? %InvalidPlayerCountError{}, Game.new(names)
      end
    end
  end

  property "a game is initialized with 2 to 10 players", [:verbose] do
    forall names <- player_names_gen() do
      Enum.sort(names) == names
      |> Game.new()
      ~> Game.players()
      ~> Enum.map(fn {_name, p} -> p.name end)
      ~> Enum.sort()
    end
  end

  property "new/1 returns an error when names are not unique", [:verbose] do
    forall name <- binary(5) do
      match? %NonUniquePlayerNameError{}, Game.new([name, name])
    end
  end

  property "all players are dealt 10 unique cards", [:verbose] do
    forall names <- player_names_gen() do
      names
      |> Game.new()
      ~> Game.players()
      ~> Enum.all?(fn {_name, p} -> Enum.count(p.hand) == 10 end)
    end
  end

  property "all players receive unique cards", [:verbose] do
    forall names <- player_names_gen() do
      Enum.count(names) * 10 == names
      |> Game.new()
      ~> Game.players()
      ~> Enum.flat_map(fn {_name, p} -> p.hand end)
      ~> Enum.uniq()
      ~> Enum.count()
    end
  end

  #
  # TESTING TABLE SETUP
  #

  property "new/1 sets up the table", [:verbose] do
    forall names <- player_names_gen() do
      table = names
      |> Game.new()
      ~> Game.table()
      match? %Table{}, table
    end
  end

  property "new/1 initializes the table with 1 card per row", [:verbose] do
    forall names <- player_names_gen() do
      [[a], [b], [c], [d]] = names
      |> Game.new()
      ~> Game.table()
      ~> Table.rows
      Enum.all?([a, b, c, d], fn c -> match? %Card{}, c end)
    end
  end

  property "new/1 initializes the table with distinct cards from the deck", [:verbose] do
    forall names <- player_names_gen() do
      game = Game.new(names)

      table_cards = game
      ~> Game.table
      ~> Table.row_heads

      player_cards = game
      ~> Game.players
      ~> Enum.flat_map(fn {_name, p} -> p.hand end)

      no_duplicates?(table_cards ++ player_cards)
    end
  end

  #
  # PLAYING CARDS
  #

  property "play/3 returns an error when the player doesn't exist", [:verbose] do
    forall game <- game_gen() do
      match? %NotPlayingError{}, Game.play(game, "non_existing_player", card(1))
    end
  end

  property "the table doesn't change if any player hasn't selected a card yet" do
    forall game <- game_gen() do
      all_players = game
      |> Game.players
      |> Map.values
      forall some_players <- subset(all_players)  do
        updated_game = some_players
        |> Enum.map(fn p -> {p.name, Enum.random(p.hand)} end)
        |> Enum.reduce(game, fn {name, card}, game -> Game.play(game, name, card) end)

        Map.equal?(game.table, updated_game.table)
      end
    end
  end

  property "all cards are added to the table once all players have selected a card", [:verbose] do
    forall game <- game_gen() do
      player_selections = game
      |> Game.players
      |> Map.values
      |> Enum.map(fn p -> {p.name, Enum.random(p.hand)} end)

      reducer = fn {name, card}, game -> Game.play(game, name, card) end
      updated_game = Enum.reduce(player_selections, game, reducer)

      table_cards = updated_game
      |> Game.table
      |> Table.rows
      |> Enum.flat_map(fn cards -> cards end)

      selected_cards = Enum.map(player_selections, fn {_, c} -> c end)

      Enum.all?(selected_cards, fn c -> c in table_cards end)


      This is not true. If a row contains the card 1, 2, 3, and 4, and if 2
      players play the card 5 and 6, the card 5 will be collected by the
      player who played the card 6.

    end
  end

end
