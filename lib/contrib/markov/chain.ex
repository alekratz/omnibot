defmodule Omnibot.Contrib.Markov.Chain do
  alias Omnibot.{Contrib.Markov.Chain, Util}

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
      {words, []} when length(words) == order -> add_weight(&2, words, nil)
      {words, []} -> add_weight(&2, Util.pad_trailing(words, nil, order), nil)
      {words, [next]} -> add_weight(&2, words, next)
    end)
  end

  def add_weight(%Chain {chain: chain, order: order}, key, word, increment \\ 1) do
    if length(key) != order do
      raise(ArgumentError, message: "invalid key (length #{length(key)} vs. order #{order})")
    end

    chain = case find_index(chain, key) do
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

  def get(chain, key) when is_list(chain) do
    item = Enum.find(chain, fn {listkey, _} -> listkey == key end)
    case item do
      nil -> nil
      {_, weights} -> weights
    end
  end

  def get(chain, key), do: get(chain.chain, key)

  def find_index(chain, key) when is_list(chain) do
    Enum.find_index(chain, fn {listkey, _} -> listkey == key end)
  end

  def find_index(chain = %Chain{}, key), do: find_index(chain.chain, key)

  def generate(chain) do
    {seed, _} = Stream.filter(chain.chain, fn {key, _} -> length(key) == chain.order end)
                |> Enum.random()
    generate(chain, seed)
  end

  def generate(chain, key) do
    do_generate(chain, key) |> Enum.join(" ")
  end

  defp do_generate(_chain, [nil | _]), do: []

  defp do_generate(chain, key) do
    weights = get(chain, key) || []
    [next | key] = key ++ [Util.weighted_random(weights)]
    [next | do_generate(chain, key)]
  end
end
