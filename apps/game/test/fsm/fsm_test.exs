defmodule FsmTest do
  use ExUnit.Case
  use PropCheck
  use PropCheck.StateM

  require Logger

  @tag :skip
  property "Simulate many games", [:verbose] do
    forall cmds <- commands(__MODULE__) do
      trap_exit do
        {history, state, result} = run_commands(__MODULE__, cmds)
        (:ok == result)
        |> when_fail(:io.format(
          """
          =======~n
          Failing command: ~p~n
          At state: ~p~n
          Result: ~p~n
          =======~n
          """,
          [Enum.at(cmds, length(history) - 1), state, result]))
        |> aggregate(command_names(cmds))
      end
    end
  end

  #
  # GENERATORS
  #

  @names ~w{Charles Henry George Harry William Elizabeth Kate Hermione Ron Peter Luke Ross John Joseph Hugo Dave}

  defp name_gen(), do: elements(@names)

  defp row_gen(), do: elements(~w(r1 r2 r3 r4)a)

  #
  # HELPERS
  #

  def select_command(state) do
    let name <- elements(Map.keys(state.players)) do
      hand = Map.fetch!(state.players, name)
      card = {:call, List, :first, [hand]}
      {:call, Game, :select, [state.sut, name, card]}
    end
  end

  def reset_selections(selections) do
    selections
    |> Enum.map(fn {name, _} -> {name, nil} end)
    |> Enum.into(Map.new)
  end

  def track_scores(players, sut) do
    players
    |> Enum.map(fn {name, _} -> {name, {:call, Game, :get_score, [sut, name]}} end)
    |> Enum.into(Map.new)
  end

  def row_selection_required?(state) do
    {_name, smallest_played_card} = Enum.min_by(state.selections, fn {_name, card} -> card end)
    {smallest_card_on_table, _size} = Enum.min_by(state.table, fn {card, _size} -> card end)

    Logger.info("smallest on table: #{inspect smallest_card_on_table} smallest selected: #{inspect smallest_played_card}")
    smallest_card_on_table > smallest_played_card
  end

  #
  # SIMULATION
  #

  defstruct [:sut, :players, :state, :selections, :scores, :table]

  @sut Game.new

  def initial_state() do
    %{r1: [c1], r2: [c2], r3: [c3], r4: [c4]} = @sut.table
    %__MODULE__{sut: @sut,
                players: %{},
                state: :init,
                selections: %{},
                scores: %{},
                table: [{c1, 1}, {c2, 1}, {c3, 1}, {c4, 1}]}
  end

  def command(%__MODULE__{sut: game, state: :init}) do
    frequency([
      {4, {:call, Game, :join, [game, name_gen()]}},
      {1, {:call, Game, :start, [game]}}
    ])
  end

  def command(%__MODULE__{state: :started} = state) do
    frequency([
      {10, select_command(state)},
      {2, {:call, Game, :play_round, [state.sut]}}
    ])
  end

  def command(%__MODULE__{state: {:pick_row, name}} = state) do
    [{:call, Game, :choose_row, [state.sut, name, row_gen()]}]
  end


  #
  # PRECONDITIONS
  #

  def precondition(state, {:call, _, :join, [_, name]}) do
    state.state != :started
    && not Map.has_key?(state.players, name)
    && map_size(state.players) < 10
  end

  def precondition(_state, {:call, Game, :start, _}) do
    true
  end

  def precondition(_state, {:call, _, :select, _}) do
    true
  end

  def precondition(state, {:call, _, :play_round, _}) do
    not Enum.any?(state.selections, fn {_name, card} -> card == nil end)
  end

  def precondition(_state, {:call, _, :choose_row, _}) do
    true
  end

  def precondition(_, {:call, module, fun, _}) do
    Logger.warn("No postcondition callback found for #{inspect module}.#{inspect fun}.")
    true
  end

  #
  # POSTCONDITIONS
  #

  def postcondition(state, {:call, _, :join, _}, result) do
    {hand, game} = result
    length(hand) == 10 && (map_size(game.players) - map_size(state.players) == 1)
  end

  def postcondition(_state, {:call, _, :start, _}, _) do
    true
  end

  def postcondition(_state, {:call, _, :select, _}, _) do
    true
  end

  def postcondition(state, {:call, _, :play_round, _}, result) do
    if row_selection_required?(state) do
      result.waiting_for != nil
    else
      Enum.all?(result.players, fn {name, player} -> state.scores[name] <= player.score end)
    end
  end

  def postcondition(_state, {:call, _, :choose_row, _}, _result) do
    true
  end

  def postcondition(_, {:call, module, fun, _}, _) do
    Logger.warn("No postcondition callback found for #{inspect module}.#{inspect fun}.")
    true
  end

  #
  # TRANSITIONS
  #

  def next_state(state, result, {:call, _, :join, [_, name]}) do
    cond do
      state.state == :started ->
        state
      map_size(state.players) == 10 ->
        state
      Map.has_key?(state.players, name) ->
        state
      true ->
        %__MODULE__{state |
                    sut: {:call, Kernel, :elem, [result, 1]},
                    players: Map.put(state.players, name, {:call, Kernel, :elem, [result, 0]}),
                    selections: Map.put(state.selections, name, nil),
                    scores: Map.put(state.scores, name, 0)}
    end
  end

  def next_state(state, result, {:call, _, :start, _}) do
    if map_size(state.players) >= 2 do
      %__MODULE__{state | sut: result, state: :started}
    else
      state
    end
  end

  def next_state(state, result, {:call, _, :select, [_, name, card]}) do
    if state.selections[name] == nil do
      %__MODULE__{state |
                  sut: result,
                  selections: %{state.selections | name => card},
                  players: Map.update!(state.players, name, fn hand -> {:call, Enum, :drop, [hand, 1]} end)}
    else
      %__MODULE__{state |
                  sut: result,
                  selections: %{state.selections | name => card},
                  players: Map.update!(state.players, name, fn hand -> {:call, List, :insert_at, [hand, -1, state.selections[name]]} end)}
    end
  end

  def next_state(state, result, {:call, _, :play_round, _}) do
    {name, smallest_played_card} = Enum.min_by(state.selections, fn {_name, card} -> card end)
    {smallest_card_on_table, _size} = Enum.min_by(state.table, fn {card, _size} -> card end)
    if smallest_card_on_table < smallest_played_card do
      %__MODULE__{state |
                  sut: result,
                  selections: reset_selections(state.selections),
                  scores: track_scores(state.scores, result)}
    else
      %__MODULE__{state | state: {:pick_row, name}}
    end
  end

  def next_state(state, _result, {:call, _, :choose_row, _}) do
    %__MODULE__{state | state: :started}
  end

  def next_state(state, _, {:call, module, fun, _}) do
    Logger.warn("No next_state callback found for #{inspect module}.#{inspect fun}.")
    state
  end
end
