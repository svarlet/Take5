defmodule Game.Model do
  @deck List.duplicate 0, 104

  defstruct players: [], hands: [], deck: @deck

  defmodule Card do
    defstruct [:number, :penalty]
  end
end
