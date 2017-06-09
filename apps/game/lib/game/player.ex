defmodule Game.Player do
  @moduledoc """
  Represent a player.

  A player has a name, a hand of cards and a selected one which can be nil.

  ## Examples

      iex> alias Game.Player
      iex> Game.Player.new("Martin")
      %Game.Player{name: "Martin"}

      iex> alias Game.Player
      iex> import Game.Card, only: :macros
      iex> Player.new("John") |> Player.has_card?(card(1, 1))
      false

      iex> alias Game.Player
      iex> import Game.Card, only: :macros
      iex> hand = [card(1, 1), card(2, 1), card(20, 3)]
      iex> "Gerald" |> Player.new(hand) |> Player.has_card?(card(2, 1))
      true

      iex> alias Game.Player
      iex> import Game.Card, only: :macros
      iex> hand = [card(1, 1), card(2, 1), card(20, 3)]
      iex> {:ok, player} = "John" |> Player.new(hand) |> Player.select(card(2, 1))
      iex> player.selected
      %Game.Card{head: 2, penalty: 1}

  """

  alias Game.Card


  @type t :: %__MODULE__{name: String.t, hand: list(Card.t), selected: Card.t}

  @empty_hand []

  @enforce_keys [:name]
  defstruct name: "", hand: @empty_hand, selected: nil

  @doc """
  Creates a new player with the provided name.

  The player will be initialized with an empty hand and no selected card. The
  name cannot be "" or nil.
  """
  @spec new(String.t) :: t
  def new(name) when name != "" and name != nil do
    %__MODULE__{name: name}
  end

  @doc """
  Creates a new player with the provided name and card.

  The name cannot be "" or nil and the cards must be a list of cards.

  See `Game.Card`.
  """
  @spec new(String.t, list(Card.t)) :: t
  def new(name, cards) when name != "" and name != nil and is_list(cards) do
    %__MODULE__{name: name, hand: cards}
  end

  @doc """
  Checks if the player possess the specified card.
  """
  @spec has_card?(t, Card.t) :: boolean()
  def has_card?(player, card) do
    Enum.member?(player.hand, card)
  end

  @doc """
  Select a card from the player's hand.

  It move the card from the hand property to the selected property. If the
  player doesn't own this card an error is returned.
  """
  @spec select(t, Card.t) :: {:ok, t} | {:error, :card_not_in_hand}
  def select(player, card) do
    if has_card?(player, card) do
      hand = List.delete(player.hand, card)
      {:ok, %__MODULE__{player | hand: hand, selected: card}}
    else
      {:error, :card_not_in_hand}
    end
  end

  #
  # INSPECT PROTOCOL
  #

  defimpl Inspect do
    def inspect(%Game.Player{selected: nil} = player, _opts) do
      "#{player.name}: #{inspect player.hand}"
    end

    def inspect(player, _opts) do
      "#{player.name}: #{player.selected} | #{inspect player.hand}"
    end
  end

end