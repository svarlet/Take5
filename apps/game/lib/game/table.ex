defmodule Game.Table do
  @moduledoc false

  @type row_id :: :r1 | :r2 | :r3 | :r4

  def new([c1, c2, c3, c4]) do
    %{r1: [c1],
      r2: [c2],
      r3: [c3],
      r4: [c4]}
  end

  def put_card(table, card) do
    with {rid, cards} <- find_destination(table, card) do
      case Enum.split([card | cards], -5) do
        {[], row} ->
          {[], put_in(table[rid], row)}
        {row, cards_to_gather} ->
          {cards_to_gather, put_in(table[rid], row)}
      end
    else
      :none ->
        {:error, :choose_row}
    end
  end

  defp find_destination(table, card) do
    case heads_by(table, fn head -> head < card end) do
      [] ->
        :none
      candidates ->
        Enum.max_by(candidates, fn {_row_id, [head | _cards]} -> head end)
    end
  end

  defp heads_by(table, filter) do
    Enum.filter(table, fn {_row_id, [head | _]} -> filter.(head) end)
  end

  def replace_row(table, rid, card) do
    {table[rid], %{table | rid => [card]}}
  end

end
