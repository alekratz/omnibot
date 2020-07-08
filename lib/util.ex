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

  def binary_search([], _key) do
    nil
  end

  def binary_search([{key, value} | _], key) do
    {0, value}
  end

  @doc "Attempts to find to find the given key in a sorted associative array."
  def binary_search(list, key) do
    {head, tail} = Enum.split(list, trunc(length(list) / 2))
    [{mid, _} | _] = tail
    if key < mid do
      binary_search(head, key)
    else
      case binary_search(tail, key) do
        nil -> nil
        {index, item} -> {index + length(head), item}
      end
    end
  end
end
