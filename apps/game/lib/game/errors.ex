defmodule Game.DuplicateNameError do
  defexception message: "Name already in use."
end

defmodule Game.GameCapacityError do
  defexception message: "The game accepts up to 10 players."
end

defmodule Game.NotEnoughPlayersError do
  defexception message: "The game requires 2 or more players to start."
end

defmodule Game.AlreadyStartedError do
  defexception message: "No player can join once the game starts."
end

defmodule Game.GameNotStartedError do
  defexception message: "Game hasn't started yet."
end

defmodule Game.NotParticipatingError do
  defexception message: "Selection is only authorized to participating players."
end

defmodule Game.InvalidSelectionError do
  defexception message: "Selection of a card not in your possession, or invalid card"
end

defmodule Game.MissingSelectionError do
  defexception message: "Every player must select a card to play the current round."
end

defmodule Game.RowSelectionError do
  defexception message: "Row selection attempt from the wrong player."
end

defmodule Game.WaitingForRowError do
  defexception message: "This action is not allowed because a player must choose a row to finish the round."
end

defmodule Game.UnexpectedRowSelectionError do
  defexception message: "No player is expected to select a row."
end

defmodule Game.GameOverError do
  defexception message: "The game is already over."
end

defmodule Game.IllegalSelectionError do
  defexception message: "Selecting a card while processing the current round is not allowed."
end
