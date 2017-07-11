defmodule GameTest do
  use ExUnit.Case, async: true
  use PropCheck
  use Exceptional

  import TestHelper

  alias Game.{Table, Card}
  alias Game.{InvalidPlayerCountError, NonUniquePlayerNameError}

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
      names == names
      |> Game.new()
      ~> Game.players()
      ~> Enum.map(fn p -> p.name end)
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
      ~> Enum.all?(fn p -> Enum.count(p.hand) == 10 end)
    end
  end

  property "all players receive unique cards", [:verbose] do
    forall names <- player_names_gen() do
      Enum.count(names) * 10 == names
      |> Game.new()
      ~> Game.players()
      ~> Enum.flat_map(fn p -> p.hand end)
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
      ~> Enum.flat_map(fn p -> p.hand end)

      no_duplicates?(table_cards ++ player_cards)
    end
  end

end
