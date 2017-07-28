defmodule FsmTest do
  use ExUnit.Case, async: true
  use PropCheck
  use PropCheck.StateM

  require Logger

  property "Simulate many games", [:verbose] do
    forall cmds <- commands(__MODULE__) do
      {history, state, result} = run_commands(__MODULE__, cmds)
      (:ok == result)
      |> when_fail(IO.puts """
      ========== REPORT ==========
      History:
      #{inspect history, pretty: true}

      State:
      #{inspect state, pretty: true}

      Result:
      #{inspect result, pretty: true}
      ============================
      """)
      |> aggregate(command_names(cmds))
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

  #
  # SIMULATION
  #

  defstruct [:sut, :players, :state]

  def initial_state() do
    %__MODULE__{sut: Game.new, players: %{}}
  end

  def command(%__MODULE__{sut: game}) do
    frequency([
      {4, {:call, Game, :join, [game, name_gen()]}},
      {1, {:call, Game, :start, [game]}}
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
                    players: Map.put(state.players, name, {:call, Kernel, :elem, [result, 0]})}
    end
  end

  def next_state(state, result, {:call, _, :start, _}) do
    if map_size(state.players) >= 2 do
      %__MODULE__{state | sut: result, state: :started}
    else
      state
    end
  end

  def next_state(state, _, {:call, module, fun, _}) do
    Logger.warn("No next_state callback found for #{inspect module}.#{inspect fun}.")
    state
  end
end
