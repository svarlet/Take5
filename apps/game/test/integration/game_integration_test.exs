defmodule GameIntegrationTest do
  use ExUnit.Case, async: true
  use Exceptional

  import Game

  alias Game.{Table, Card}

  test "a normal game" do
    game = %Game{deck: 1..100, table: Table.new([101, 102, 103, 104])}
    with {p1_hand, game} <- join(game, "p1"),
         {p2_hand, game} <- join(game, "p2") do
      result = game
      ~> start()

      # round 1
      ~> select("p1", 1)
      ~> select("p2", 11)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 2
      ~> select("p1", 2)
      ~> select("p2", 12)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 3
      ~> select("p1", 3)
      ~> select("p2", 13)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 4
      ~> select("p1", 4)
      ~> select("p2", 14)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 5
      ~> select("p1", 5)
      ~> select("p2", 15)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 6
      ~> select("p1", 6)
      ~> select("p2", 16)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 7
      ~> select("p1", 7)
      ~> select("p2", 17)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 8
      ~> select("p1", 8)
      ~> select("p2", 18)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 9
      ~> select("p1", 9)
      ~> select("p2", 19)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      # round 10
      ~> select("p1", 10)
      ~> select("p2", 20)
      ~> play_round()
      ~> choose_row("p1", :r2)
      ~> play_round()

      cards_collected_by_p1 = [102 | Enum.take(p1_hand, 9)] ++ Enum.take(p2_hand, 9)
      assert get_score(result, "p1") == cards_collected_by_p1
      |> Enum.map(&Card.penalty/1)
      |> Enum.sum
      assert get_score(result, "p2") == 0
    end
  end
end
