defmodule Game.Deck do
  import Game.Card, only: [card: 1]

  @deck for rank <- 1..104, do: card(rank)

  def deck(), do: Enum.shuffle(@deck)

end
