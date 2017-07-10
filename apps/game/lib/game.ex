defmodule Game do
  use Exceptional

  alias Game.{Player, Deck, Table}
  import Game.Card, only: [card: 1]

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
    hands = Deck.deck()
    |> Enum.shuffle()
    |> Stream.chunk(10)

    players = player_names
    |> Stream.zip(hands)
    |> Enum.map(fn {name, hand} -> Player.new(name, hand) end)

    table = %Table{row_0: card(1), row_1: card(1), row_2: card(1), row_3: card(1)}

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

end
