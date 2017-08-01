defmodule Game.PlayingState do
  @moduledoc false

  @behaviour Game.State

  alias Game.{
    Player,
    ProcessingRoundState,
    AlreadyStartedError,
    NotParticipatingError,
    InvalidSelectionError,
    MissingSelectionError,
    UnexpectedRowSelectionError
  }

  def join(_game, _name), do: %AlreadyStartedError{}

  def start(game), do: game

  def select(game, name, card) do
    cond do
      not Game.participating?(game, name) ->
        %NotParticipatingError{}
      not Player.has_card?(game.players[name], card) ->
        %InvalidSelectionError{}
      Player.has_selection?(game.players[name]) ->
        update_in(game.players[name], fn player ->
          %{player | selection: card, hand: [player.selection | player.hand]}
        end)
      true ->
        update_in(game.players[name], fn player ->
          %{player | selection: card, hand: List.delete(player.hand, card)}
        end)
    end
  end

  def play_round(game) do
    if Game.missing_selection?(game) do
      %MissingSelectionError{}
    else
      game
      |> Game.set_state(ProcessingRoundState)
      |> Game.play_round
    end
  end

  def choose_row(_game, _name, _rid), do: %UnexpectedRowSelectionError{}

end
