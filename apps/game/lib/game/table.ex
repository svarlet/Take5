defmodule Game.Table do
  @moduledoc """
  This module represents a table.

  A table has 4 rows represented as lists of cards. Initially, all rows are
  empty. The head of every row is the last card put in the row.
  """

  alias Game.Card

  @type t :: %__MODULE__{row_0: list(Card.t), row_1: list(Card.t), row_2: list(Card.t), row_3: list(Card.t)}

  @empty_row []

  defstruct row_0: @empty_row, row_1: @empty_row, row_2: @empty_row, row_3: @empty_row

  @doc """
  Create a new table with empty rows.
  """
  @spec new() :: t
  def new do
    %__MODULE__{}
  end

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
  Initialize a table with the 4 provided cards.
  """
  @spec set(t, nonempty_list(Card.t)) :: t
  def set(table, [c0, c1, c2, c3]) do
    %__MODULE__{table | row_0: [c0], row_1: [c1], row_2: [c2], row_3: [c3]}
  end

  @doc """
  Put a card on the table.

  The card is placed in one of the rows, following the highest head among
  those with a lower head.
  """
  @spec put(t, Card.t) :: t
  def put(table, card) do
    Map.update(table, row_for_card(table, card), @empty_row, fn row -> [card | row] end)
  end

  defp row_for_card(table, card) do
    %__MODULE__{row_0: [c0 | _],
                row_1: [c1 | _],
                row_2: [c2 | _],
                row_3: [c3 | _]} = table

    relevant_row_head = [c0, c1, c2, c3]
    |> Enum.filter(fn a_card -> Card.compare(a_card, card) == :lt end)
    |> Enum.max_by(fn card -> card.head end)

    case relevant_row_head do
      ^c0 -> :row_0
      ^c1 -> :row_1
      ^c2 -> :row_2
      ^c3 -> :row_3
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
