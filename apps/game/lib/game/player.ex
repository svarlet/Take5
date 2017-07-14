defmodule Game.Player do
  @moduledoc """
  Represent a player.

  A player has a name, a hand of cards and a selected one which can be nil.

  ## Examples

      iex> alias Game.Player
      iex> import Game.Card, only: [card: 1]
      iex> hand = [card(1), card(2), card(20)]
      iex> "Gerald" |> Player.new(hand) |> Player.has_card?(card(2))
      true

      iex> alias Game.Player
      iex> import Game.Card, only: [card: 1]
      iex> hand = [card(1), card(2), card(20)]
      iex> player = "John" |> Player.new(hand) |> Player.select(card(2))
      iex> player.selected
      %Game.Card{rank: 2, penalty: 1}

  """

  use Exceptional

  alias Game.Card

  @type t :: %__MODULE__{name: String.t, hand: list(Card.t), selected: Card.t, gathered_cards: list(Card.t)}

  @enforce_keys [:name]
  defstruct name: "", hand: [], selected: :none, gathered_cards: []

  defmodule InvalidPlayerNameError do
    defexception message: "Player name cannot be blank."
  end

  defmodule InvalidHandError do
    defexception message: "nil is not a valid hand."
  end

  defmodule CardNotOwnedError do
    defexception message: "The player doesn't own this card."
  end

  @doc """
  Creates a new player with the provided name and cards.

  The name cannot be "" or nil and the cards must be a list of cards.
  See `Game.Card`.
  """
  @spec new(String.t, list(Card.t)) :: t | Exception.t
  def new("", _), do: %InvalidPlayerNameError{}
  def new(_, nil), do: %InvalidHandError{}
  def new(name, cards), do: %__MODULE__{name: name, hand: cards}

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
    player
    |> validate_card(card)
    ~> do_select(card)
  end

  defp validate_card(player, card) do
    if has_card?(player, card) do
      player
    else
      %CardNotOwnedError{}
    end
  end

  defp do_select(%__MODULE__{selected: :none} = player, card) do
    %__MODULE__{player | hand: List.delete(player.hand, card), selected: card}
  end

  defp do_select(player, card) do
    %__MODULE__{player | hand: [player.selected | player.hand], selected: card}
  end

  def no_selection?(%__MODULE__{selected: :none}), do: true
  def no_selection?(_), do: false

  #
  # INSPECT PROTOCOL
  #

  defimpl Inspect do
    def inspect(%Game.Player{selected: :none} = player, _opts) do
      "#{player.name}: #{inspect player.hand}"
    end

    def inspect(player, _opts) do
      "#{player.name}: #{inspect player.selected} | #{inspect player.hand}"
    end
  end

end
