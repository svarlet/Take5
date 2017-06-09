defmodule Game.Card do
  @moduledoc """
  Represents a card.

  A card has a head value in the range 1..104 and a penalty value which is either
  1, 2, 3, 5, or 7. The `Inspect` protocol is implemented to show only the head
  of the card in order to get a more concise output.

  A macro is provided to simplify the manipulation of cards.

  ## Examples

      iex> import Game.Card, only: :macros
      iex> card(10, 3)
      %Game.Card{head: 10, penalty: 3}

  """

  @type head :: 1..104
  @type penalty :: [1 | 2 | 3 | 5 | 7]
  @type t :: %__MODULE__{head: head, penalty: penalty}

  @enforce_keys [:head, :penalty]
  defstruct head: 1, penalty: 1

  defmacro card(head, penalty) do
    quote do
      %Game.Card{head: unquote(head), penalty: unquote(penalty)}
    end
  end

  defimpl Inspect do
    def inspect(card, _opts) do
      "#{card.head}"
    end
  end
end
