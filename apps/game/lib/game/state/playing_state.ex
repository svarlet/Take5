defmodule Game.PlayingState do
  @moduledoc false

  @behaviour Game.State

  alias Game.{
    Player,
    Table,
    AlreadyStartedError,
    NotParticipatingError,
    InvalidSelectionError,
    MissingSelectionError,
    UnexpectedRowSelectionError
  }

  alias Game.WaitingForRowState

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
      do_play_round(game)
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
      [] -> game
    end
  end

  def choose_row(_game, _name, _rid), do: %UnexpectedRowSelectionError{}

end
