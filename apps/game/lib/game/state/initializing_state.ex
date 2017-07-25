defmodule Game.InitializingState do
  @moduledoc false

  @behaviour Game.State

  alias Game.{
    Deck,
    Player,
    PlayingState,
    GameCapacityError,
    DuplicateNameError,
    NotEnoughPlayersError,
    GameNotStartedError
  }

  def join(%Game{players: ps}, _name) when map_size(ps) == 10 do
    %GameCapacityError{}
  end

  def join(game, name) when is_binary(name) do
    if Game.participating?(game, name) do
      %DuplicateNameError{}
    else
      {hand, deck} = Deck.deal(game.deck, 10)
      players = Map.put(game.players, name, Player.new(hand))
      {hand, %Game{game | players: players, deck: deck}}
    end
  end

  def start(%Game{players: ps}) when map_size(ps) < 2 do
    %NotEnoughPlayersError{}
  end

  def start(game) do
    %Game{game | state: PlayingState}
  end

  def select(_game, _name, _card), do: %GameNotStartedError{}

  def play_round(_game), do: %GameNotStartedError{}

  def choose_row(_game, _name, _row_id), do: %GameNotStartedError{}
end
