defmodule GameTest do
  use ExUnit.Case, async: true
  use PropCheck

  import TestHelper

  doctest Game.Deck
  doctest Game.Card
  doctest Game.Player
  doctest Game.Table

  property "a game cannot be created with less than 2 players or more than 10 players", [:verbose] do
    forall count <- union([integer(0, 1), integer(11, :inf)]) do
      forall names <- vector(count, player_name_gen()) do
        try do
          Game.new(names)
        rescue
          FunctionClauseError -> true
        else
          _ -> false
        end
      end
    end
  end

  property "a game is initialized with 2 to 10 players", [:verbose] do
    forall names <- list(player_name_gen()) do
      implies Enum.count(names) in 2..10 do
        names == names
        |> Game.new()
        |> Game.players()
        |> Enum.map(fn p -> p.name end)
      end
    end
  end
end
