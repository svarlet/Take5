ExUnit.start()

defmodule TestHelper do
  use PropCheck

  import Game.Model, only: [deck: 0]
  import Game.Card, only: [card: 1]

  alias Game.{Model, Player, Table}

  @names ~w{Hugo Seb Geraldo Fausto Joao Julie Arthur Daniel Ziad Emily}

  @spec cards_gen(0..104) :: {list(Card.t), list(Card.t)}
  def cards_gen(quantity) do
    let deck <- exactly(Enum.to_list(deck())) do
      {cards, rest_of_deck} = deck
      |> Enum.shuffle()
      |> Enum.split(quantity)

    {Enum.sort_by(cards, fn c -> c.head end), MapSet.new(rest_of_deck)}
    end
  end

  def table_gen do
    let row_sizes <- vector(4, integer(1, 5)) do
      quantity_of_cards = Enum.sum(row_sizes)
      let {cards, deck} <- cards_gen(quantity_of_cards) do
        [row0, row1, row2, row3] = multisplit(cards, row_sizes)
        table = %Table{row_0: row0, row_1: row1, row_2: row2, row_3: row3}
        {table, deck}
      end
    end
  end

  defp multisplit(list, [_size]) do
    [list]
  end

  defp multisplit(list, [size | sizes]) do
    {elements, rest} = Enum.split(list, size)
    [elements | multisplit(rest, sizes)]
  end

  def card_and_table_gen do
    let {table, deck} <- table_gen() do
      {Enum.random(deck), table}
    end
  end

  def pair_of_cards_gen() do
    let pivot <- integer(1, 103) do
      let {lower_head, higher_head} <- {integer(1, pivot), integer(pivot + 1, 104)} do
        {card(lower_head), card(higher_head)}
      end
    end
  end

  def remaining_deck(hands) do
    dealt_cards_set = hands
    |> Enum.map(&MapSet.new/1)
    |> Enum.reduce(&MapSet.union/2)

    MapSet.difference(deck(), dealt_cards_set)
  end

  def player_name_gen, do: elements(@names)

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
  This generator generates and starts models of 2 to 10 players.
  """
  def model_gen do
    let player_count <- integer(2, 10) do
      @names
      |> Enum.take(player_count)
      |> Enum.reduce(%Model{}, fn name, model -> model |> Model.add_player(name) |> elem(1) end)
      |> Model.start
      |> elem(1)
    end
  end

  defp select_first_card(%Player{hand: [card | _]} = player) do
    player
    |> Player.select(card)
    |> elem(1)
  end

  @doc """
  This helper selects a card on behalf of players of the provided model.

  This function takes a model and a keyword which specifies how many
  selections should occur: `players: :all` to select a card for every
  player of the model, `players: :all_but_one` to select a card for
  all but a random player of the model.

  The selected card is the first card of the player's hand.
  """
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
