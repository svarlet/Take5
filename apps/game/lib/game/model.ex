defmodule Game.Model do
  @deck (for n <- 1..104, into: %{} do
          cond do
            n == 55 -> {55, 7}
            rem(n, 5) == 0 && rem(n, 10) != 0 -> {n, 2}
            rem(n, 11) == 0 -> {n, 5}
            rem(n, 10) == 0 -> {n, 3}
            true -> {n, 1}
          end
        end)

  defstruct players: [], hands: [], deck: @deck

  defmodule Card do
    defstruct [:number, :penalty]
  end
end
