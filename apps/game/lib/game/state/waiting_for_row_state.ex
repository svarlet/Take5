defmodule Game.WaitingForRowState do
  @behaviour Game.State

  alias Game.{
    ProcessingRoundState,
    AlreadyStartedError,
    WaitingForRowError,
    RowSelectionError
  }

  def join(_game, _name), do: %AlreadyStartedError{}

  def start(game), do: game

  def select(_game, _name, _card), do: %WaitingForRowError{}

  def play_round(_game), do: %WaitingForRowError{}

  def choose_row(game, name, row_id) do
    if game.waiting_for != name do
      %RowSelectionError{}
    else
      game
      |> Game.set_waiting_for(nil)
      |> Game.set_chosen_row_id(row_id)
      |> Game.set_state(ProcessingRoundState)
    end
  end
end
