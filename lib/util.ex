defmodule Omnibot.Util do
  def string_empty?(s), do: String.length(s) == 0

  def string_or_nil(s), do: if(string_empty?(s), do: nil, else: s)

  def now_unix, do: now_unix("Etc/UTC")

  def now_unix(tz), do: DateTime.now!(tz) |> DateTime.to_unix()
end
