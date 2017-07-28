defmodule FsmTest do
  use ExUnit.Case
  use PropCheck
  use PropCheck.StateM

  require Logger

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
          =======~n
          Result: ~p~n
          History: ~p~n
          """,
          [Enum.at(cmds, length(history) - 1), state, result, history]))
        |> aggregate(command_names(cmds))
      end
    end
  end

  #
  # GENERATORS
  #

  @names ~w{Charles Henry George Harry William Elizabeth Kate Hermione Ron Peter Luke Ross John Joseph Hugo Dave}

  defp name_gen() do
    elements(@names)
  end

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

  #
  # SIMULATION
  #

  defstruct [:sut, :players, :state, :selections]

  def initial_state() do
    %__MODULE__{sut: Game.new, players: %{}, state: :init, selections: %{}}
  end

  def command(%__MODULE__{sut: game, state: :init}) do
    frequency([
      {4, {:call, Game, :join, [game, name_gen()]}},
      {1, {:call, Game, :start, [game]}}
    ])
  end

  def command(%__MODULE__{state: :started} = state) do
    frequency([
      {6, select_command(state)}
    ])
  end

  def precondition(state, {:call, _, :join, [_, name]}) do
    state.state != :started
    && not Map.has_key?(state.players, name)
    && map_size(state.players) < 10
  end

  def precondition(_state, {:call, Game, :start, _}) do
    true
  end

  def precondition(state, {:call, _, :select, _}) do
    state.state == :started
  end

  def precondition(_, {:call, module, fun, _}) do
    Logger.warn("No postcondition callback found for #{inspect module}.#{inspect fun}.")
    true
  end

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

  def postcondition(_, {:call, module, fun, _}, _) do
    Logger.warn("No postcondition callback found for #{inspect module}.#{inspect fun}.")
    true
  end

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
                    selections: Map.put(state.selections, name, nil)}
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

  def next_state(state, _, {:call, module, fun, _}) do
    Logger.warn("No next_state callback found for #{inspect module}.#{inspect fun}.")
    state
  end
end
