defmodule Omnibot.Contrib.Markov.Chain do
  alias Omnibot.Contrib.Markov.Chain

  @enforce_keys [:order]
  defstruct order: 2, chain: []

  def train(chain, line) when is_binary(line) do
    train(chain, line |> String.split(~r/\s+/))
  end

  def train(chain, words) when is_list(words) do
    order = chain.order

    Enum.filter(words, &(String.length(&1) > 0))
    |> Enum.chunk_every(order + 1, 1) # this gives us a "sliding window" effect
    |> Enum.reduce(chain, &case Enum.split(&1, order) do
      {words, []} -> if length(words) == order,
          # Null case for the chain; this is an "end" state
          do: add_weight(&2, words, nil),
          else: &2 # TODO ? train [a, nil] -> b ?
      {words, [next]} -> add_weight(&2, words, next)
    end)
  end

  def add_weight(%Chain {chain: chain, order: order}, key, word, increment \\ 1) do
    if length(key) != order, do: raise(ArgumentError, message: "invalid key (length #{length(key)} vs. order #{order})")
    chain = case Enum.find_index(chain, fn {listkey, _} -> listkey == key end) do
      # Insert weight
      nil -> [{key, %{word => increment}} | chain]
      # Update weight
      index -> List.update_at(
          chain,
          index,
          fn {key, mapping} -> {key, Map.update(mapping, word, increment, &(&1 + increment))} end
      )
    end
    %Chain{chain: chain, order: order}
  end
end
