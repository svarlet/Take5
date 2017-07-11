ExUnit.start()

defmodule TestHelper do
  use PropCheck

  import Game.Deck, only: [deck: 0]
  import Game.Card, only: [card: 1]

  alias Game.{Player, Table}

  @names ~w{Hugo Seb Geraldo Fausto Joao Julie Arthur Daniel Ziad Emily}

  def no_duplicates?(enum) do
    Enum.count(enum) == enum
    |> Enum.uniq
    |> Enum.count
  end

  @spec cards_gen(0..104) :: {list(Card.t), list(Card.t)}
  def cards_gen(quantity) do
    let deck <- exactly(deck()) do
      {cards, rest_of_deck} = Enum.split(deck, quantity)

    {Enum.sort_by(cards, fn c -> c.rank end), rest_of_deck}
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
      let {lower_rank, higher_rank} <- {integer(1, pivot), integer(pivot + 1, 104)} do
        {card(lower_rank), card(higher_rank)}
      end
    end
  end

  def remaining_deck(hands) do
    deck() -- Enum.flat_map(hands, &(&1))
  end

  def player_name_gen, do: elements(@names)

  def player_names_gen() do
    let {names, count} <- {exactly(@names), integer(2, 10)} do
      Enum.take(names, count)
    end
  end

  def hand_gen(min_size \\ 0, max_size \\ 10) do
    let size <- integer(min_size, max_size) do
      Enum.take(deck(), size)
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

end
