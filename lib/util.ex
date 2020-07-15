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

  def weighted_random(items) when is_map(items) do
    Enum.to_list(items) |> weighted_random()
  end

  def weighted_random([]), do: nil

  def weighted_random(items) do
    value = items
            |> Enum.reduce(0, fn {_, weight}, total -> total + weight end)
            |> :rand.uniform()
    select_item(items, value)
  end

  defp select_item([{item, _}], _), do: item

  defp select_item([{item, weight} | _], index) when weight >= index, do: item

  defp select_item([{_, weight} | tail], index), do: select_item(tail, index - weight)

  def pad_trailing(list, _what, len) when length(list) >= len, do: list

  def pad_trailing(list, what, len), do: pad_trailing(list ++ [what], what, len)
end
