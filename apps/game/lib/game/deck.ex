defmodule Game.Deck do
  @moduledoc false

  @deck 1..104

  def new, do: Enum.shuffle(@deck)

  def deal(deck, n), do: Enum.split(deck, n)
end
