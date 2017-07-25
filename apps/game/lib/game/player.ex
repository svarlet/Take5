defmodule Game.Player do
  @moduledoc false

  alias Game.Card

  defstruct hand: [], selection: nil, score: 0

  def new(hand), do: %__MODULE__{hand: hand}

  def has_card?(player, card), do: Enum.member?(player.hand, card)

  def has_selection?(player), do: player.selection != nil

  def get_score(player), do: player.score

  def gather_cards(player, []) do
    %__MODULE__{player | selection: nil}
  end

  def gather_cards(player, cards) do
    %__MODULE__{player | score: player.score + Card.penalty(cards), selection: nil}
  end
end
