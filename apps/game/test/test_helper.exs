ExUnit.start()

defmodule TestHelper do
  use PropCheck

  import Game.Model, only: [deck: 0]

  alias Game.{Model, Player}

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

  def hand_size_gen(at_least: min, at_most: max) when min in 0..10 and max in min..10 do
    integer(min, max)
  end

  def hand_size_gen(at_least: min) when min in 0..10 do
    integer(min, 10)
  end

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
  def players_gen(players: [at_least: pmin, at_most: pmax], cards: card_specs) do
    let {p_count, hand_size} <- {integer(pmin, pmax), hand_size_gen(card_specs)} do
      case hand_size do
        0 ->
          @names
          |> Enum.take(p_count)
          |> Enum.map(&Player.new/1)
        _ ->
          deck()
          |> Enum.shuffle
          |> Enum.chunk(hand_size)
          |> Enum.zip(Enum.take(@names, p_count))
          |> Enum.map(fn {hand, name} -> Player.new(name, hand) end)
      end
    end
  end

  def model_gen do
    let player_count <- integer(2, 10) do
      @names
      |> Enum.take(player_count)
      |> Enum.reduce(%Model{}, fn name, model -> model |> Model.add_player(name) |> elem(1) end)
      |> Model.start
      |> elem(1)
    end
  end

  def select_first_card(%Player{hand: [card | _]} = player) do
    player
    |> Player.select(card)
    |> elem(1)
  end

  def select_cards(model, players: :all) do
    all_players = model.players
    |> Map.values
    |> Enum.map(&select_first_card/1)
    |> Enum.into(%{}, fn player -> {player.name, player} end)
    %Model{model | players: all_players}
  end

  def select_cards(model, players: :all_but_one) do
    [player | others] = Map.values(model.players)

    all_players = others
    |> Enum.map(&select_first_card/1)
    |> List.insert_at(0, player)
    |> Enum.shuffle
    |> Enum.into(%{}, fn player -> {player.name, player} end)

    %Model{model | players: all_players, status: :started}
  end

end
