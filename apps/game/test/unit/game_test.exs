defmodule GameTest do
  use ExUnit.Case, async: true
  use Exceptional

  alias Game.{
    Table,
    DuplicateNameError,
    GameCapacityError,
    NotEnoughPlayersError,
    AlreadyStartedError,
    GameNotStartedError,
    NotParticipatingError,
    InvalidSelectionError,
    MissingSelectionError,
    RowSelectionError
  }

  #
  # HELPERS
  #

  defp is_card?(rank), do: 1 <= rank && rank <= 104

  defp distinct_cards?(cards) do
    Enum.count(cards) == cards
    |> Enum.uniq
    |> Enum.count
  end

  defp cards(%{r1: [c1], r2: [c2], r3: [c3], r4: [c4]}), do: [c1, c2, c3, c4]

  defp add_many_players(game, qtity) when qtity > 0 do
    1..qtity
    |> Enum.map(fn id -> "p#{id}" end)
    |> Enum.reduce(game, fn p, g -> g |> Game.join(p) ~> elem(1) end)
  end

  defp play_all_firsts(game) do
    Enum.reduce(game.players, game, fn {name, p}, g ->
      Game.select(g, name, hd(p.hand))
    end)
  end



  #
  # SETUP HELPERS
  #

  defp do_join(context) do
    {p1_cards, game} = Game.join(context.game, "p1")
    {p2_cards, game} = Game.join(game, "p2")
    [game: game, p1_cards: p1_cards, p2_cards: p2_cards]
  end

  defp do_select(context) do
    game = context.game
    ~> Game.start
    ~> Game.select("p1", hd(context.p1_cards))
    ~> Game.select("p2", hd(context.p2_cards))
    [game: game]
  end

  defp do_play_round(context) do
    [game: Game.play_round(context.game)]
  end



  #
  # TESTS
  #

  describe "Initializing the table:" do
    test "given a new game then the table is set with 4 cards in 4 rows" do
      assert Game.new
      |> Game.get_table
      |> cards
      |> Enum.all?(&is_card?/1)
    end

    test "given a new game then the table is set with distinct cards" do
      assert Game.new
      |> Game.get_table
      |> cards
      |> distinct_cards?
    end

    test "given 2 games then both tables are initialized differently" do
      g1_cards = Game.new |> Game.get_table |> cards
      g2_cards = Game.new |> Game.get_table |> cards
      assert g1_cards != g2_cards
    end
  end



  describe "Joining a game:" do
    test "given 2 players with the same name when they join then the second to join is rejected" do
      {_hand, game} = Game.new
      |> Game.join("p1")
      assert Game.join(game, "p1") == %DuplicateNameError{}
    end

    test "given a new game then up to 10 players can join" do
      Game.new
      |> add_many_players(10)
    end

    test "given a game with 10 players when an 11th player tries to join then an exception is returned" do
      %GameCapacityError{} = add_many_players(Game.new, 11)
    end

    test "when a player joins a game, he is dealt 10 cards" do
      {cards, _game} = Game.new
      |> Game.join("p1")
      assert Enum.count(cards) == 10
    end

    test "when a player joins a game then he is dealt 10 unique cards" do
      with game <- Game.new,
           {p1_cards, game} <- Game.join(game, "p1"),
           {p2_cards, _game} <- Game.join(game, "p2") do
        assert distinct_cards?(p1_cards ++ p2_cards)
      else
        error -> flunk "Test setup failed. (reason: #{inspect error})"
      end
    end

    test "when a player joins a game then he shouldn't receive the same hand than last game" do
      with game <- Game.new,
           {p1_cards, _} <- Game.join(game, "p1"),
           game_bis <- Game.new,
           {p1_cards_bis, _} <- Game.join(game_bis, "p1") do
        assert p1_cards != p1_cards_bis
      else
        error -> flunk "Test setup failed. (reason: #{inspect error})"
      end
    end

    test "when the game is empty then the game cannot start" do
      %NotEnoughPlayersError{} = Game.start(Game.new)
    end

    test "when the game has a single player then the game cannot start" do
      with {_cards, game} <- Game.join(Game.new, "p1") do
        %NotEnoughPlayersError{} = Game.start(game)
      else
        error -> flunk "Test setup failed. (reason: #{inspect error})"
      end
    end

    test "when the game has started then an attempt to join is rejected" do
      with game <- Game.new,
           {_, game} <- Game.join(game, "p1"),
           {_, game} <- Game.join(game, "p2"),
             game <- Game.start(game) do
        %AlreadyStartedError{} = Game.join(game, "p3")
      else
        error -> flunk "Test setup failed. (reason: #{inspect error})"
      end
    end
  end



  describe "Errors when selecting cards" do
    setup do
      with game <- Game.new,
           {p1_cards, game} <- Game.join(game, "p1"),
           {p2_cards, game} <- Game.join(game, "p2"),
             game <- Game.start(game) do
        [game: game, p1_cards: p1_cards, p2_cards: p2_cards]
      else
        error -> flunk "Test setup failed. (reason: #{inspect error})"
      end
    end

    test "when the game hasn't started yet then a selection is rejected", _context do
      with game <- Game.new,
           {p1_cards, game} <- Game.join(game, "p1"),
           {_p2_cards, game} <- Game.join(game, "p2") do
        %GameNotStartedError{} = Game.select(game, "p1", hd(p1_cards))
      else
        error -> flunk "Test setup failed. (reason: #{inspect error})"
      end
    end

    test "when a player does not participate then his selection is rejected", context do
      %NotParticipatingError{} = Game.select(context.game, "p3", 1)
    end

    test "when a player selects a card which doesn't belong to him then his selection is rejected", context do
      %InvalidSelectionError{} = Game.select(context.game, "p1", hd(context.p2_cards))
    end

    test "when a player selects an already selected card then the selection is rejected", context do
      %InvalidSelectionError{} = context.game
      ~> Game.select("p1", hd(context.p1_cards))
      ~> Game.select("p1", hd(context.p1_cards))
    end
  end



  describe "Selecting a card:" do
    setup [:do_join]

    @tag game: Game.new
    test "when a player changes his selection then the previously selected card is selectable again", context do
      %Game{} = context.game
      ~> Game.start
      ~> Game.select("p1", hd(context.p1_cards))
      ~> Game.select("p1", Enum.at(context.p1_cards, 1))
      ~> Game.select("p1", hd(context.p1_cards))
    end
  end



  describe "Errors when playing the round:" do
    setup [:do_join]

    @tag game: Game.new
    test "given an unstarted game then play_round/1 returns an error", _context do
      assert Game.new
      |> Game.play_round
      == %GameNotStartedError{}
    end

    @tag game: Game.new
    test "when some players haven't selected a card yet then the round cannot be played", context do
      %MissingSelectionError{} = context.game
      ~> Game.start
      ~> Game.select("p1", hd(context.p1_cards))
      ~> Game.play_round()
    end
  end



  describe "Playing the round:" do
    setup [:do_join, :do_select, :do_play_round]

    @tag game: %Game{deck: 5..104, table: Table.new([1, 2, 3, 4])}
    test "given a table with no full row when all selected cards are higher then cards are added", context do
      assert %{r1: [1], r2: [2], r3: [3], r4: [15, 5, 4]} == Game.get_table(context.game)
    end

    @tag game: %Game{deck: 9..104, table: %{r1: [1], r2: [2], r3: [3], r4: [8, 7, 6, 5, 4]}}
    test "given a full row then the row is replaced by the new card", context do
      assert %{r1: [1], r2: [2], r3: [3], r4: [19, 9]} == Game.get_table(context.game)
    end

    @tag game: %Game{deck: 9..104, table: %{r1: [1], r2: [2], r3: [3], r4: [8, 7, 6, 5, 4]}}
    test "given a full row when a player put the next card in it then he gathers these cards", context do
      assert Game.get_score(context.game, "p1") == 6
      assert Game.get_score(context.game, "p2") == 0
    end

    @tag game: Game.new
    test "given 10 players when they play a sequence of cards then 2 will gather cards", _context do
      game = %Game{deck: 5..104, table: Table.new([1, 4, 3, 2])}
      |> add_many_players(10)
      |> Game.start()
      |> play_all_firsts()
      |> Game.play_round()
      assert Game.get_score(game, "p5") == 9
      assert Game.get_score(game, "p10") == 15
    end
  end



  describe "Choosing a row:" do
    setup [:do_join, :do_select]

    @tag game: %Game{deck: 1..100, table: Table.new([101, 102, 103, 104])}
    test "when a row needs to be chosen then the table remains unchanged", context do
      assert context.game
      ~> Game.play_round
      ~> Game.get_table
      == Table.new([101, 102, 103, 104])
    end

    @tag game: %Game{deck: 1..100, table: Table.new([101, 102, 103, 104])}
    test "when a row needs to be chosen then another player cannot choose it", context do
      assert %RowSelectionError{} == context.game
      ~> Game.play_round
      ~> Game.choose_row("p2", :r3)
    end

    @tag game: %Game{deck: 1..100, table: Table.new([101, 102, 103, 104])}
    test "when a row is chosen then the round can be played normally", context do
      game = context.game
      ~> Game.play_round
      ~> Game.choose_row("p1", :r2)
      ~> Game.play_round
      assert %{r1: [101], r2: [11, 1], r3: [103], r4: [104]} == Game.get_table(game)
      assert 0 == Game.get_score(game, "p2")
      assert 1 == Game.get_score(game, "p1")
    end
  end



  describe "Scores:" do
    test "given a player who doesn't participate when getting his score then an error is returned" do
      %NotParticipatingError{} = Game.new
      |> Game.get_score("non existing player")
    end

    test "given a new game and a player when the player joins the game then his score is 0" do
      {_hand, game} = Game.new
      |> Game.join("p1")
      assert 0 == Game.get_score(game, "p1")
    end
  end
end
