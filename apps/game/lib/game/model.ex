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
      ...>                   {:ok, model2_started} <- Game.Model.start(model2) do
      ...>                model2_started
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

  import Game.Card, only: [card: 1]

  alias Game.{Card, Player, Table}

  @deck (1..104 |> Enum.map(&card/1) |> MapSet.new)
  @empty_table %Table{}

  @spec deck() :: MapSet.t
  def deck(), do: @deck

  @doc false
  defstruct status: :init, players: Map.new, table: @empty_table, deck: @deck

  @type row :: list(Card.t)
  @type t :: %__MODULE__{status: :init | :started, players: Map.t, table: Table.t, deck: MapSet.t}
  @type success :: {:ok, t}
  @type error :: {:error, atom}

  @spec add_player(t, String.t) :: success | error
  def add_player(model, name) do
    cond do
      started?(model) ->
        {:error, :game_has_already_started}
      has_player?(model, name) ->
        {:error, :already_participating}
      count_players(model) >= 10 ->
        {:error, :at_capacity}
      true ->
        new_player = Player.new(name)
        {:ok, %__MODULE__{model | players: Map.put(model.players, name, new_player)}}
    end
  end

  @spec has_player?(t, String.t) :: true | false
  def has_player?(model, name) do
    Map.has_key? model.players, name
  end

  @spec count_players(t) :: non_neg_integer
  def count_players(model) do
    Enum.count(model.players)
  end

  @spec remove_player(t, String.t) :: success | error
  def remove_player(model, name) do
    if has_player?(model, name) do
      {:ok, %__MODULE__{model | players: Map.delete(model.players, name)}}
    else
      {:error, :not_participating}
    end
  end

  @spec start(t) :: success | error
  def start(model) do
    if count_players(model) >= 2 do
      result = model
      |> Map.put(:status, :started)
      |> deal
      |> arrange_table
      {:ok, result}
    else
      {:error, :not_enough_players}
    end
  end

  @spec started?(t) :: boolean()
  def started?(model), do: model.status == :started

  defp deal(model) do
    {distributable, remaining_cards} = model.deck
    |> Enum.shuffle
    |> Enum.split(10 * count_players(model))

    hands = Enum.chunk(distributable, 10)

    players = model.players
    |> Map.keys
    |> Enum.zip(hands)
    |> Enum.map(fn {name, hand} -> {name, Player.new(name, hand)} end)
    |> Enum.into(Map.new)

    %__MODULE__{model | players: players, deck: remaining_cards}
  end

  defp arrange_table(model) do
    {[c0, c1, c2, c3], deck} = Enum.split(model.deck, 4)
    %__MODULE__{model | deck: deck, table: %{0 => [c0], 1 => [c1], 2 => [c2], 3 => [c3]}}
  end

  @spec select(t, String.t, Card.t) :: success | error
  def select(model, name, card) do
    cond do
      !started?(model) ->
        {:error, :game_not_started}
      !has_player?(model, name) ->
        {:error, :not_playing}
      !Player.has_card?(model.players[name], card) ->
        {:error, :card_not_in_hand}
      true ->
        case Player.select(model.players[name], card) do
          {:ok, player} ->
            players = put_in(model.players, [name], player)
            {:ok, %__MODULE__{model | players: players}}
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @spec process_round(t) :: success | error
  def process_round(model) do
    cond do
      !started?(model) ->
        {:error, :game_not_started}
      Enum.any?(model.players, fn {_name, player} -> Player.no_selection?(player) end) ->
        {:error, :missing_selection}
      true ->
        # model.players
        # |> Map.values
        # |> Enum.sort_by(fn {_name, player} -> player. end)
        {:ok, model}
    end
  end

  #
  # Inspect protocol
  #

  defimpl Inspect do
    import Inspect.Algebra

    alias Game.Model

    @nesting 2

    def inspect(model, _opts) do
      [&document_status/1, &document_table/1, &document_players/1]
      |> Enum.map(fn builder -> builder.(model) end)
      |> fold_doc(&line/2)
      |> nested("Model")
    end

    defp document_status(model) do
      model.status
      |> nested("status")
    end

    defp document_table(%Model{table: table}) do
      table
      |> nested("table")
    end

    defp document_players(%Model{players: []}) do
      "none"
      |> nested("players")
    end

    defp document_players(model) do
      model.players
      |> Enum.map(fn {_name, player} -> Kernel.inspect player end)
      |> fold_doc(&line/2)
      |> nested("players")
    end

    def nested(items, title) do
      "#{title}:"
      |> line(items)
      |> nest(@nesting)
    end
  end

end
