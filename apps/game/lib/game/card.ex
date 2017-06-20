defmodule Game.Card do
  @moduledoc """
  Represents a card.

  A card has a head value in the range 1..104 and a penalty value which is either
  1, 2, 3, 5, or 7. The `Inspect` protocol is implemented to show only the head
  of the card in order to get a more concise output.

  ## Examples

      iex> import Game.Card
      iex> card(10)
      %Game.Card{head: 10, penalty: 3}

  """

  @type head :: 1..104
  @type penalty :: [1 | 2 | 3 | 5 | 7]
  @type t :: %__MODULE__{head: head, penalty: penalty}

  @enforce_keys [:head, :penalty]
  defstruct head: 1, penalty: 1

  def card(head) do
    %__MODULE__{head: head, penalty: penalty(head)}
  end

  def penalty(head) do
    cond do
      head == 55 -> 7
      rem(head, 5) == 0 && rem(head, 10) != 0 -> 2
      rem(head, 11) == 0 -> 5
      rem(head, 10) == 0 -> 3
      true -> 1
    end
  end

  def compare(c1, c2) do
    cond do
      c1.head > c2.head -> :gt
      c1.head == c2.head -> :eq
      c1.head < c2.head -> :lt
    end
  end

  #
  # INSPECT PROTOCOL IMPLEMENTATION
  #

  defimpl Inspect do
    def inspect(card, _opts) do
      String.pad_leading("#{card.head}", 3)
    end
  end
end
