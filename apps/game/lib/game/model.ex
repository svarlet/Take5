defmodule Game.Model do
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

  def add_player(model, player) do
    cond do
      MapSet.member?(model.players, player) ->
        {:error, {:already_participating, model}}
      Enum.count(model.players) >= 10 ->
        {:error, {:at_capacity, model}}
      true ->
        {:ok, %__MODULE__{model | players: MapSet.put(model.players, player)}}
    end
  end

  def has_player?(model, player) do
    Enum.member?(model.players, player)
  end

  def remove_player(model, player) do
    if MapSet.member?(model.players, player) do
      {:ok, %__MODULE__{model | players: MapSet.delete(model.players, player)}}
    else
      {:error, {:not_participating, model}}
    end
  end

  def count_players(model) do
    Enum.count(model.players)
  end

  def start(model) do
    if count_players(model) >= 2 do
      {:ok, %__MODULE__{model | status: :started}}
    else
      {:error, {:not_enough_players, model}}
    end
  end

  def deal(model) do
    if model.status == :started do
      a_hand = List.duplicate 0, 10
      hands = for player <- model.players, into: Map.new do
        {player, a_hand}
      end
      {:ok, %__MODULE__{model | hands: hands}}
    else
      {:error, {:not_started, model}}
    end
  end

  defmodule Card do
    defstruct [:number, :penalty]
  end
end
