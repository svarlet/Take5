defmodule Game.Table do
  @moduledoc """
  This module represents a table.

  A table has 4 rows represented as lists of cards. Initially, all rows are
  empty.
  """

  @type t :: %__MODULE__{row_0: list(Card.t), row_1: list(Card.t), row_2: list(Card.t), row_3: list(Card.t)}

  defstruct row_0: [], row_1: [], row_2: [], row_3: []

  @doc """
  Create a new table with empty rows.
  """
  def new do
    %__MODULE__{}
  end

  @doc """
  Initialize a table with the 4 provided cards.
  """
  def set(table, [c0, c1, c2, c3]) do
    %__MODULE__{table | row_0: [c0], row_1: [c1], row_2: [c2], row_3: [c3]}
  end

  @doc """
  Put a card on the table.
  """
  def put(table, _card) do
    table
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
