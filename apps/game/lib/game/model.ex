defmodule Game.Model do
  @deck List.duplicate 0, 104

  defstruct players: [], hands: [], deck: @deck

end
