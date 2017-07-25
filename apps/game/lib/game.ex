defmodule Game do
  alias Game.{Player, Deck, Table, NotParticipatingError}

  defstruct state: Game.InitializingState,
    players: %{},
    deck: nil,
    table: nil,
    chosen_row: nil,
    waiting_for: nil

  #
  # API
  #

  def new() do
    {cards, deck} = Deck.deal(Deck.new, 4)
    %__MODULE__{deck: deck, table: Table.new(cards)}
  end

  def join(game, name), do: game.state.join(game, name)

  def start(game), do: game.state.start(game)

  def select(game, name, card), do: game.state.select(game, name, card)

  def participating?(game, name), do: Map.has_key?(game.players, name)

  def play_round(game), do: game.state.play_round(game)

  def choose_row(game, name, row_id), do: game.state.choose_row(game, name, row_id)

  #
  # HELPERS
  #

  def get_table(%__MODULE__{table: table}), do: table

  def set_table(game, table), do: %__MODULE__{game | table: table}

  def missing_selection?(game) do
    Enum.any?(game.players, fn {_name, p} -> not Player.has_selection?(p) end)
  end

  def selections(game) do
    game.players
    |> Enum.filter(fn {_name, %Player{selection: card}} -> card != nil end)
    |> Enum.map(fn {name, %Player{selection: card}} -> {name, card} end)
    |> Enum.sort_by(fn {_name, card} -> card end)
  end

  def dispatch_gathered_cards(game, name, cards) do
    update_in(game.players[name], &Player.gather_cards(&1, cards))
  end

  def get_score(game, name) do
    if participating?(game, name) do
      Player.get_score(game.players[name])
    else
      %NotParticipatingError{}
    end
  end

  def set_chosen_row_id(game, rid), do: %__MODULE__{game | chosen_row: rid}

  def set_state(game, state), do: %__MODULE__{game | state: state}

  def set_waiting_for(game, name), do: %__MODULE__{game | waiting_for: name}

end
