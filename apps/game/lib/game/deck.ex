defmodule Game.Deck do
  import Game.Card, only: [card: 1]

  @deck for head <- 1..104, do: card(head)

  def deck(), do: @deck


end
