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

  use Quark

  @type head :: 1..104
  @type penalty :: [1 | 2 | 3 | 5 | 7]
  @type t :: %__MODULE__{head: head, penalty: penalty}

  @enforce_keys [:head, :penalty]
  defstruct head: 1, penalty: 1

  def card(head) do
    %__MODULE__{head: head, penalty: penalty(head)}
  end

  @doc """
  Creates the list of cards for the provided list of heads.

  ## Examples

    iex> Game.Card.cards([1, 2 , 3])
    [%Game.Card{head: 1, penalty: 1}, %Game.Card{head: 2, penalty: 1}, %Game.Card{head: 3, penalty: 1}]

  """
  @spec cards(list(1..104)) :: list(Card.t)
  def cards(heads) do
    Enum.map(heads, &card/1)
  end

  @spec penalty(head) :: penalty
  def penalty(head) do
    cond do
      head == 55 -> 7
      rem(head, 5) == 0 && rem(head, 10) != 0 -> 2
      rem(head, 11) == 0 -> 5
      rem(head, 10) == 0 -> 3
      true -> 1
    end
  end

  @spec compare(t, t) :: :gt | :eq | :lt
  def compare(c1, c2) do
    cond do
      c1.head > c2.head -> :gt
      c1.head == c2.head -> :eq
      c1.head < c2.head -> :lt
    end
  end

  defpartial smaller_than(ref_card, a_card) do
    compare(a_card, ref_card) == :lt
  end

  @doc """
  Finds the closest lower card to a card in a list of cards.

  Returns such a card if it exists or nil otherwise.

  ## Examples

      iex> some_cards = [10, 20, 30, 40] |> Enum.map(&Game.Card.card/1)
      iex> a_card = Game.Card.card(35)
      iex> Game.Card.closest_lower_card(a_card, some_cards)
      %Game.Card{head: 30, penalty: 3}

      iex> some_cards = [10, 20, 30, 40] |> Enum.map(&Game.Card.card/1)
      iex> a_card = Game.Card.card(5)
      iex> Game.Card.closest_lower_card(a_card, some_cards)
      nil

  """
  @spec closest_lower_card(Card.t, list(Card.t)) :: Card.t | nil
  def closest_lower_card(card, cards) do
    cards
    |> Enum.filter(smaller_than(card))
    |> Enum.sort_by(fn c -> c.head end)
    |> List.last
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
