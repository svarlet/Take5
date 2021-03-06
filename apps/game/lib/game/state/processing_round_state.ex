defmodule Game.ProcessingRoundState do
  @moduledoc false

  @behaviour Game.State

  alias Game.{
    Table,
    WaitingForRowState,
    PlayingState,
    GameOverState,
    AlreadyStartedError,
    IllegalSelectionError,
    UnexpectedRowSelectionError
  }

  def join(_, _), do: %AlreadyStartedError{}

  def start(game), do: game

  def select(_, _, _), do: %IllegalSelectionError{}

  def play_round(game) do
    game = do_play_round(game)
    if Game.game_over?(game) do
      Game.set_state(game, GameOverState)
    else
      game
    end
  end

  defp do_play_round(%Game{chosen_row: rid} = game) when rid != nil do
    with [{name, card} | _] <- Game.selections(game) do
      {cards, table} = Table.replace_row(game.table, rid, card)
      game
      |> Game.set_table(table)
      |> Game.dispatch_gathered_cards(name, cards)
      |> Game.set_chosen_row_id(nil)
      |> do_play_round
    end
  end

  defp do_play_round(game) do
    with [{name, card} | _] <- Game.selections(game) do
      case Table.put_card(game.table, card) do
        {:error, :choose_row} ->
          game
          |> Game.set_state(WaitingForRowState)
          |> Game.set_waiting_for(name)
        {cards, table} ->
          game
          |> Game.set_table(table)
          |> Game.dispatch_gathered_cards(name, cards)
          |> do_play_round
      end
    else
      [] ->
        game
        |> Game.set_state(PlayingState)
    end
  end

  def choose_row(_, _, _), do: %UnexpectedRowSelectionError{}
end
