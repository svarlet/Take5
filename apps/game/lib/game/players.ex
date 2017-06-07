defmodule Game.Players do
  @moduledoc false

  @typep card_head :: 1..104
  @typep penalty :: [1 | 2 | 3 | 5 | 7]
  @typep card :: {card_head, penalty}
  @typep hand :: list(card)
  @typep player :: %{hand: hand, played: :none | card}
  @type t :: %{required(String.t) => player}

  @empty_hand []

  @spec new :: t
  def new do
    %{}
  end

  @spec add_player(t, String.t) :: {:ok, t} | {:error, :atom}
  def add_player(players, name) do
    cond do
      has_player?(players, name) ->
        {:error, :already_participating}
      count_players(players) >= 10 ->
        {:error, :at_capacity}
      true ->
        {:ok, Map.put(players, name, @empty_hand)}
    end
  end

  @spec has_player?(t, String.t) :: true | false
  def has_player?(players, name) do
    Map.has_key? players, name
  end

  @spec count_players(t) :: non_neg_integer
  def count_players(players) do
    Enum.count(players)
  end

  @spec remove_player(t, String.t) :: {:ok, t} | {:error, :atom}
  def remove_player(players, name) do
    if has_player?(players, name) do
      {:ok, Map.delete(players, name)}
    else
      {:error, :not_participating}
    end
  end


end
