defmodule Game.GameOverState do
  @behaviour Game.State

  alias Game.GameOverError

  def join(_game, _name), do: %GameOverError{}

  def start(_game), do: %GameOverError{}

  def select(_game, _name, _card), do: %GameOverError{}

  def play_round(_game), do: %GameOverError{}

  def choose_row(_game, _name, _row_id), do: %GameOverError{}
end
