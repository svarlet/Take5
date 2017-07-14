defmodule Game do
  use Exceptional

  alias Game.{Player, Deck, Table}
  import Deck, only: [deck: 0]

  defstruct [:players, :table]

  defmodule InvalidPlayerCountError do
    defexception message: "Invalid player count, must be between 2 and 10."
  end

  defmodule NonUniquePlayerNameError do
    defexception message: "All players must have a unique name."
  end

  def new(player_names) do
    player_names
    |> validate_players_count
    ~> validate_unique_names
    ~> create()
  end

  defp create(player_names) do
    player_count = Enum.count(player_names)

    {cards, [c0, c1, c2, c3 | _deck]} = Enum.split(deck(), player_count * 10)

    hands = Enum.chunk(cards, 10)

    players = player_names
    |> Enum.zip(hands)
    |> Enum.map(fn {name, hand} -> Player.new(name, hand) end)
    |> Map.new(fn p -> {p.name, p} end)

    table = Table.new(c0, c1, c2, c3)

    %__MODULE__{players: players, table: table}
  end

  defp validate_players_count(player_names) do
    player_count = Enum.count(player_names)
    if 2 <= player_count && player_count <= 10 do
      player_names
    else
      %InvalidPlayerCountError{}
    end
  end

  defp validate_unique_names(names) do
    unique_names_count = names
    |> Enum.uniq()
    |> Enum.count()

    if unique_names_count == Enum.count(names) do
      names
    else
      %NonUniquePlayerNameError{}
    end
  end

  def players(%__MODULE__{players: players}), do: players

  def table(%__MODULE__{table: table}), do: table

  defmodule NotPlayingError do
    defexception message: "The specified player is not participating in this game."
  end

  def play(game, player_name, card) do
    game
    |> validate_player_participation(player_name)
    ~> do_play(player_name, card)
  end

  defp do_play(game, name, card) do
    players = game
    |> Game.players
    |> Map.update!(name, fn p -> Player.select(p, card) end)

    %__MODULE__{game | players: players}
  end

  defp validate_player_participation(game, name) do
    if Map.has_key?(game.players, name) do
      game
    else
      %NotPlayingError{}
    end
  end

  #
  # INSPECT PROTOCOL IMPLEMENTATION
  #

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(game, _) do
      "Game"
      |> line(inspect_players(game))
      |> line(inspect_table(game))
      |> group
      |> nest(2)
    end

    defp inspect_players(game) do
      players_doc =
        if Enum.empty?(Game.players(game)) do
          "none"
        else
          game
          |> Game.players
          |> Map.values
          |> Enum.map(&Kernel.inspect/1)
          |> fold_doc(&line/2)
        end

      "Players"
      |> line(players_doc)
      |> nest(2)
    end

    defp inspect_table(game) do
      table_doc = game
      |> Game.table
      |> Kernel.inspect

      "Table"
      |> line(table_doc)
      |> nest(2)
    end

  end

end
