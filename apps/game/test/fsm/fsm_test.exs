defmodule FsmTest do
  use ExUnit.Case, async: true
  use PropCheck
  use PropCheck.StateM

  require Logger

  alias Game.{
    DuplicateNameError,
    GameCapacityError
  }

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

  defstruct [:sut, :players]

  def initial_state() do
    %__MODULE__{sut: Game.new, players: %{}}
  end

  def command(%__MODULE__{sut: game}) do
    frequency([
      {10, {:call, Game, :join, [game, name_gen()]}},
      {1, {:call, Game, :start, [game]}}
    ])
  end

  def precondition(_, {:call, _, :join, _}) do
    true
  end

  def precondition(state, {:call, Game, :start, _}) do
    true
  end

  def precondition(_, {:call, module, fun, _}) do
    Logger.warn("No postcondition callback found for #{inspect module}.#{inspect fun}.")
    true
  end

  def postcondition(state, {:call, _, :join, [_, name]}, result) do
    cond do
      map_size(state.players) == 10 ->
        result == %GameCapacityError{}
      Map.has_key?(state.players, name) ->
        result == %DuplicateNameError{} or Logger.warn("something fishy here")
      true ->
        {hand, game} = result
        length(hand) == 10 && (map_size(game.players) - map_size(state.players) == 1)
    end
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
    cond do
      map_size(state.players) >= 2 ->
        %__MODULE__{state | sut: result}
      true ->
        state
    end
  end

  def next_state(state, _, {:call, module, fun, _}) do
    Logger.warn("No next_state callback found for #{inspect module}.#{inspect fun}.")
    state
  end
end
