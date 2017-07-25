defmodule Game.Card do

  @type t :: 1..104

  def penalty(rank) when rank in 1..104 do
    cond do
      rank == 55 -> 7
      rem(rank, 11) == 0 -> 5
      rem(rank, 10) == 0 -> 3
      rem(rank, 5) == 0 -> 2
      true -> 1
    end
  end

  def penalty([]) do
    0
  end

  def penalty([rank | rest]) when rank in 1..104 do
    penalty(rank) + penalty(rest)
  end
end
