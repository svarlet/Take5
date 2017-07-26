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

  defp name_gen() do
    elements(~w{Charles Henry George Harry William Elizabeth Kate Hermione Ron Peter Luke Ross})
  end

  #
  # SIMULATION
  #

  defstruct [:sut, :players, :state]

  def initial_state() do
    %__MODULE__{sut: Game.new, players: %{}, state: :init}
  end

  def command(%__MODULE__{sut: game, state: :init}) do
    frequency([
      {10, {:call, Game, :join, [game, name_gen()]}},
      {1, {:call, Game, :start, [game]}}
    ])
  end

  def command(%__MODULE__{state: :started}) do
    oneof([{:call, IO, :puts, ["yay!"]}])
  end

  def precondition(state, {:call, _, :join, [_, name]}) do
    map_size(state.players) < 10 && not Map.has_key?(state.players, name)
  end

  def precondition(state, {:call, Game, :start, _}) do
    map_size(state.players) >= 2
  end

  def precondition(_, {:call, _, :puts, _}) do
    true
  end

  def postcondition(%__MODULE__{players: ps_before}, {:call, _, :join, _}, {hand, %Game{players: ps_after}}) do
    length(hand) == 10 && (map_size(ps_after) - map_size(ps_before) == 1)
  end

  def postcondition(_state, {:call, _, :start, _}, _) do
    true
  end

  def postcondition(_, {:call, _, :puts, _}, _) do
    true
  end

  def next_state(state, result, {:call, _, :join, [_, name]}) do
    %__MODULE__{state |
                sut: {:call, Kernel, :elem, [result, 1]},
                players: Map.put(state.players, name, {:call, Kernel, :elem, [result, 0]})}
  end

  def next_state(state, result, {:call, _, :start, _}) do
    %__MODULE__{state | sut: result, state: :started}
  end

  def next_state(state, _, {:call, _, :puts, _}) do
    state
  end
end
