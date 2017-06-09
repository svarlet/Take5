ExUnit.start()

defmodule TestHelper do
  import Game.Card, only: [card: 2]

  @deck (for n <- 1..104, into: MapSet.new do
             cond do
               n == 55 -> card(55, 7)
               rem(n, 5) == 0 && rem(n, 10) != 0 -> card(n, 2)
               rem(n, 11) == 0 -> card(n, 5)
               rem(n, 10) == 0 -> card(n, 2)
               true -> card(n, 1)
             end
         end)

  def deck do
    @deck
  end

  def penalty(head) do
    cond do
      head == 55 -> {55, 7}
      rem(head, 5) == 0 && rem(head, 10) != 0 -> {head, 2}
      rem(head, 11) == 0 -> {head, 5}
      rem(head, 10) == 0 -> {head, 3}
      true -> {head, 1}
    end
  end
end
