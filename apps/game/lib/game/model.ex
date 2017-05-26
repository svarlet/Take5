defmodule Game.Model do

  @moduledoc """
  Defines a game.

  A Model represents a game. It validates and perform state updates and transitions. When an update
  cannot be performed, the model is returned unchanged within a tuple describing the reason of the
  failure.

  ## Examples

      iex> model = with model <- %Game.Model{},
      ...>              {:ok, model} <- Game.Model.add_player(model, "player 1"),
      ...>              {:ok, model} <- Game.Model.add_player(model, "player 2"),
      ...>              {:ok, model} <- Game.Model.start(model),
      ...>              {:ok, model} <- Game.Model.deal(model) do
      ...>           model
      ...>         end
      iex> Game.Model.has_player?(model, "player 1")
      true
      iex> Game.Model.has_player?(model, "not a player")
      false
      iex> Game.Model.count_players(model)
      2
      iex> model.status
      :started

  """

  @deck (for n <- 1..104, into: MapSet.new do
          cond do
            n == 55 -> {55, 7}
            rem(n, 5) == 0 && rem(n, 10) != 0 -> {n, 2}
            rem(n, 11) == 0 -> {n, 5}
            rem(n, 10) == 0 -> {n, 3}
            true -> {n, 1}
          end
        end)

  defstruct status: :init, players: MapSet.new, hands: Map.new, table: [], deck: @deck

  @type t :: %__MODULE__{status: atom, players: MapSet.t, hands: Map.t, table: list, deck: MapSet.t}
  @type success :: {:ok, t}
  @type error :: {:error, {atom, t}}

  @spec add_player(t, term) :: success | error
  def add_player(model, player) do
    cond do
      model.status == :started ->
        {:error, {:game_has_already_started, model}}
      MapSet.member?(model.players, player) ->
        {:error, {:already_participating, model}}
      Enum.count(model.players) >= 10 ->
        {:error, {:at_capacity, model}}
      true ->
        {:ok, %__MODULE__{model | players: MapSet.put(model.players, player)}}
    end
  end

  @spec has_player?(t, term) :: true | false
  def has_player?(model, player) do
    Enum.member?(model.players, player)
  end

  @spec remove_player(t, term) :: success | error
  def remove_player(model, player) do
    if MapSet.member?(model.players, player) do
      {:ok, %__MODULE__{model | players: MapSet.delete(model.players, player)}}
    else
      {:error, {:not_participating, model}}
    end
  end

  @spec count_players(t) :: non_neg_integer
  def count_players(model) do
    Enum.count(model.players)
  end

  @spec start(t) :: success | error
  def start(model) do
    if count_players(model) >= 2 do
      {:ok, %__MODULE__{model | status: :started}}
    else
      {:error, {:not_enough_players, model}}
    end
  end

  @spec deal(t) :: success | error
  def deal(model) do
    if model.status == :started do
      shuffled_deck = Enum.shuffle(model.deck)
      unassigned_hands = Stream.chunk(shuffled_deck, 10)
      hands = model.players
      |> Stream.zip(unassigned_hands)
      |> Enum.into(Map.new)
      {:ok, %__MODULE__{model | hands: hands, deck: shuffled_deck}}
    else
      {:error, {:not_started, model}}
    end
  end

  defmodule Card do
    defstruct [:number, :penalty]
  end
end
