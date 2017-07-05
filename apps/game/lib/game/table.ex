defmodule Game.Table do
  @moduledoc """
  This module represents a table.

  A table has 4 rows represented as lists of cards. Initially, all rows are
  empty. The head of every row is the last card put in the row.

  ## Examples

      iex> %Game.Table{}
      ...> |> Game.Table.set(Game.Card.card(1), Game.Card.card(2), Game.Card.card(3), Game.Card.card(4))
      ...> |> Game.Table.row_heads()
      ...> |> Enum.map(fn card -> card.head end)
      [1, 2, 3, 4]

  """

  alias Game.Card

  @type t :: %__MODULE__{row_0: list(Card.t), row_1: list(Card.t), row_2: list(Card.t), row_3: list(Card.t)}

  @empty_row []

  defstruct row_0: @empty_row, row_1: @empty_row, row_2: @empty_row, row_3: @empty_row

  @doc """
  Returns a list of the 4 rows of the provided table.
  """
  @spec rows(t) :: nonempty_list(nonempty_list(Card.t))
  def rows(table) do
    [table.row_0, table.row_1, table.row_2, table.row_3]
  end

  @doc """
  Returns a list of the last card put in each row.
  """
  @spec row_heads(t) :: nonempty_list(Card.t)
  def row_heads(%__MODULE__{row_0: [c0 | _], row_1: [c1 | _], row_2: [c2 | _], row_3: [c3 | _]}) do
    [c0, c1, c2, c3]
  end

  @doc """
  Returns a list of the last card of each row using the provided predicate.
  """
  @spec row_heads_by(t, (Card.t -> boolean())) :: list(Card.t)
  def row_heads_by(table, predicate) do
    table
    |> row_heads
    |> Enum.filter(predicate)
  end

  @doc """
  Returns true if any head satisfies the given predicate.
  """
  @spec any_head?(t, (Card.t -> boolean())) :: true | false
  def any_head?(table, predicate) do
    table
    |> row_heads()
    |> Enum.any?(predicate)
  end

  @doc """
  Initialize a table with the 4 provided cards.
  """
  @spec set(t, Card.t, Card.t, Card.t, Card.t) :: t
  def set(table, c0, c1, c2, c3) do
    %__MODULE__{table | row_0: [c0], row_1: [c1], row_2: [c2], row_3: [c3]}
  end

  @doc """
  Put a card on the table.

  The card is placed in one of the rows, following the highest head among
  those with a lower head.
  """
  @spec put(t, Card.t) :: t
  def put(table, card) do
    case row_for_card(table, card) do
      :no_matching_row -> {:error, {:choose_row, card}}
      row_id -> Map.update(table, row_id, @empty_row, fn row -> [card | row] end)
    end
  end

  defp row_for_card(table, card) do
    %__MODULE__{row_0: [c0 | _],
                row_1: [c1 | _],
                row_2: [c2 | _],
                row_3: [c3 | _]} = table

    closest = Card.closest_lower_card(card, row_heads(table))

    case closest do
      ^c0 -> :row_0
      ^c1 -> :row_1
      ^c2 -> :row_2
      ^c3 -> :row_3
      _ -> :no_matching_row
    end
  end

  #
  # INSPECT PROTOCOL IMPLEMENTATION
  #

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(table, _oppts) do
      table
      |> Map.take([:row_0, :row_1, :row_2, :row_3])
      |> Enum.map(fn {row_id, cards} -> "#{row_id}: #{inspect cards}" end)
      |> fold_doc(&line/2)
    end
  end

end
