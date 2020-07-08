defmodule Omnibot.Util do
  def string_empty?(s), do: String.length(s) == 0

  def string_or_nil(s), do: if(string_empty?(s), do: nil, else: s)

  def now_unix, do: now_unix("Etc/UTC")

  def now_unix(tz), do: DateTime.now!(tz) |> DateTime.to_unix()

  @doc """
  Inserts a zero-width space character inside of a nickname so that it won't
  create a notification for that user.
  """
  def denotify_nick(nick) do
    String.graphemes(nick) |> Enum.join("\u200b")
  end
end
