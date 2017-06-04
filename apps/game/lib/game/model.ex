defmodule Game.Model do

  @moduledoc """
  Defines a game.

  A Model represents a game. It validates and perform state updates and transitions. When an update
  cannot be performed, the model is returned unchanged within a tuple describing the reason of the
  failure.

  ## Examples

      iex> game_model = with model <- %Game.Model{},
      ...>                   {:ok, model1} <- Game.Model.add_player(model, "player 1"),
      ...>                   {:ok, model2} <- Game.Model.add_player(model1, "player 2"),
      ...>                   {:ok, model2_started} <- Game.Model.start(model2),
      ...>                   {:ok, model2_dealt} <- Game.Model.deal(model2_started) do
      ...>                model2_dealt
      ...>              end
      iex> Game.Model.has_player?(game_model, "player 1")
      true
      iex> Game.Model.has_player?(game_model, "not a player")
      false
      iex> Game.Model.count_players(game_model)
      2
      iex> Game.Model.started?(game_model)
      true

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

  @empty_hand []

  @doc false
  defstruct status: :init, players: Map.new, table: [], deck: @deck

  @opaque t :: %__MODULE__{status: atom, players: Map.t, table: list, deck: MapSet.t}
  @type success :: {:ok, t}
  @type error :: {:error, {atom, t}}

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(model, _opts) do
      document_builders = [&document_status/1, &document_table/1, &document_players/1]
      result = document_builders
      |> Enum.map(fn builder -> builder.(model) end)
      |> fold_doc(&line/2)

      nested_document("Model", result, 4)
    end

    defp document_status(model) do
      "status: #{model.status}"
    end

    defp document_players(%Game.Model{players: players}) when players in [%{}, nil] do
      "players: No player."
    end

    defp document_players(model) do
      player_hand = fn {player, hand} ->
        "#{player}: #{document_cards(hand)}"
      end

      players = model.players
      |> Enum.map(player_hand)
      |> fold_doc(&line/2)

      nested_document("players", players, 4)
    end

    defp document_cards(cards) do
      cards
      |> Enum.map(fn {head, _penalty} -> head end)
      |> Enum.join("-")
    end

    defp document_table(%Game.Model{table: table}) when table in [[], nil] do
      "table: Empty"
    end

    defp document_table(model) do
      rows = model.table
      |> Enum.map(&document_cards/1)
      |> fold_doc(&line/2)

      nested_document("table", rows, 4)
    end

    defp nested_document(title, items, nesting_level) do
      "#{title}:"
      |> line(items)
      |> nest(nesting_level)
    end
  end

  @spec add_player(t, term) :: success | error
  def add_player(model, player) do
    cond do
      started?(model) ->
        {:error, :game_has_already_started}
      has_player?(model, player) ->
        {:error, :already_participating}
      count_players(model) >= 10 ->
        {:error, :at_capacity}
      true ->
        {:ok, %__MODULE__{model | players: Map.put(model.players, player, @empty_hand)}}
    end
  end

  @spec has_player?(t, term) :: true | false
  def has_player?(model, player) do
    Map.has_key? model.players, player
  end

  @spec remove_player(t, term) :: success | error
  def remove_player(model, player) do
    if has_player?(model, player) do
        {:ok, %__MODULE__{model | players: Map.delete(model.players, player)}}
    else
        {:error, :not_participating}
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
      {:error, :not_enough_players}
    end
  end

  @spec started?(t) :: true | false
  def started?(model) do
    model.status in [:started, :dealt]
  end

  defp dealt?(model) do
    model.status == :dealt
  end

  @spec deal(t) :: success | error
  def deal(model) do
    cond do
      dealt?(model) ->
        {:error, :already_dealt_cards}
      started?(model) ->
        shuffled_deck = Enum.shuffle(model.deck)
        unassigned_hands = Stream.chunk(shuffled_deck, 10)
        players = model.players
        |> Map.keys
        |> Stream.zip(unassigned_hands)
        |> Enum.into(Map.new)
        {:ok, %__MODULE__{model | players: players, deck: shuffled_deck, status: :dealt}}
      true ->
        {:error, :not_started}
    end
  end

end
