ExUnit.start()

defmodule TestHelper do
  use PropCheck

  import Game.Model, only: [deck: 0]

  alias Game.Player

  @names ~w{Hugo Seb Geraldo Fausto Joao Julie Arthur Daniel Ziad Emily}

  def random_hand(size) do
    deck()
    |> Enum.shuffle
    |> Enum.take(size)
  end

  def remaining_deck(hands) do
    dealt_cards_set = hands
    |> Enum.map(&MapSet.new/1)
    |> Enum.reduce(&MapSet.union/2)

    MapSet.difference(deck(), dealt_cards_set)
  end

  def player_name_gen, do: elements(@names)

  def hand_size_gen, do: integer(0, 10)

  def hand_gen(min_size \\ 0, max_size \\ 10) do
    let size <- integer(min_size, max_size) do
      deck()
      |> Enum.shuffle
      |> Enum.take(size)
    end
  end

  @doc """
  This generator generates a player with a random name and a
  hand of 0 to 10 random cards.
  To generate multiple players at once, use `players_gen`
  instead.
  """
  def player_gen() do
    player_gen(cards: [at_least: 0, at_most: 10])
  end

  @doc """
  This generator is similar to `player_gen/1` but the
  minimum and maximum number of cards can be specified with a
  keyword parameter.

  The keyword parameter must contain a `cards` key associated
  to a keyword with `at_least` and `at_most` keys associated to
  integer values in the range 0..10.
  """
  def player_gen(cards: [at_least: x, at_most: y]) when x in 0..10 and y in x..10 do
    let {name, hand} <- {player_name_gen(), hand_gen(x, y)} do
      Player.new(name, hand)
    end
  end

  def player_gen(cards: [at_least: x]) when x in 0..10 do
    player_gen(cards: [at_least: x, at_most: 10])
  end

  @doc """
  This generator generates a bounded random number of players.

  Every player will have a unique name, a hand of unique
  random cards and a hand of the same size than the players
  generated in the same batch.

  It is particulary useful if multiple players needs to be created
  with an assigned hand from a common deck. Using the `player_gen`
  for this task would certainly generate some players with
  identical names and cards in common, which is impossible in a
  regular game.
  """
  def players_gen(at_least, upto) do
    let {qtity, hand_size} <- {integer(at_least, upto), hand_size_gen()} do
      deck()
      |> Enum.shuffle
      |> Enum.chunk(hand_size)
      |> Enum.zip(Enum.take(@names, qtity))
      |> Enum.map(fn {hand, name} -> Player.new(name, hand) end)
    end
  end

end
