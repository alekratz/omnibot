defmodule Omnibot.Contrib.Markov.Chain do
  alias Omnibot.{Contrib.Markov.Chain, Util}

  @enforce_keys [:order]
  defstruct order: 2, chain: []

  def train(%Chain {chain: chain, order: order}, words) when is_list(words) do

    Enum.filter(words, &(String.length(&1) > 0))
    |> Enum.chunk_every(order + 1, 1) # this gives us a "sliding window" effect
    |> Enum.reduce(chain, &case Enum.split(words, order) do
      {words, []} -> if length(&1) == order,
          # Null case for the chain; this is an "end" state
          do: train_one(%Chain {chain: &2, order: order}, words, nil)
          # else: TODO ? train [a, nil] -> b ?
      {words, [next]} ->
        train_one(%Chain {chain: &2, order: order}, words, next)
    end
    )
  end

  def train_one(%Chain {chain: _chain, order: _order}, _key, _value) do
  end

  def lookup(%Chain {chain: chain, order: order}, key) do
    if length(key) != order, do: raise(ArgumentError, message: "invalid key (length #{length(key)} vs. order #{order})")
    case Util.binary_search(chain, key) do
      {_index, value} -> value
      nil -> nil
    end
  end

  def put(%Chain {chain: _chain, order: _order}, _key, _value) do
  end
end
