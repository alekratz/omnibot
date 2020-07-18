defmodule Omnibot.Contrib.Markov.Chain do
  alias Omnibot.{Contrib.Markov.Chain, Util}
  require Logger

  @enforce_keys [:order]
  defstruct order: 2, chain: %{}, reply_chance: 0.01

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

  def add_weight(%Chain{chain: chain, order: order}, key, word, increment \\ 1) do
    if length(key) != order do
      raise(ArgumentError, message: "invalid key (length #{length(key)} vs. order #{order})")
    end

    # %{
    #   ["word1", "word2"] => %{"target" => weight}
    # }
    chain = Map.update(chain, key, %{word => increment},
      fn weights -> Map.update(weights, word, increment, &(increment + &1)) end)
    %Chain{chain: chain, order: order}
  end

  def generate(chain) do
    {seed, _} = Stream.filter(chain.chain, fn {key, _} -> length(key) == chain.order end)
                |> Enum.random()
    generate(chain, seed)
  end

  def generate(chain, key) do
    do_generate(chain, key) |> Enum.join(" ")
  end

  def load!(path) do
    {:ok, chain} = load(path)
    chain
  end

  def load(path) do
    Logger.debug("Loading markov chain #{path}")
    with {:ok, contents} <- File.read(path),
         do: {:ok, :erlang.binary_to_term(contents)}
  end

  def save!(chain, path) do
    :ok = save(chain, path)
  end

  def save(chain, path) do
    File.write!(path, :erlang.term_to_binary(chain))
  end

  def merge(lhs, rhs) do
    if lhs.order != rhs.order do
      raise(ArgumentError, message: "markov chain orders must match (#{lhs.order} vs #{rhs.order})")
    end

    merged = Map.merge(lhs.chain, rhs.chain,
      fn _k, lhs, rhs -> Map.merge(lhs, rhs, fn _k, w1, w2-> w1 + w2 end) end
    )
    %Chain{order: lhs.order, chain: merged}
  end

  def merge([chain]), do: chain

  def merge([chain | tail]), do: merge(tail) |> merge(chain)

  defp do_generate(_chain, [nil | _]), do: []

  defp do_generate(chain, key) do
    weights = chain.chain[key] || %{}
    [next | key] = key ++ [Util.weighted_random(weights)]
    [next | do_generate(chain, key)]
  end

  def chain_sum(chain) do
    Enum.reduce(chain.chain, 0, &(weight_sum(&1) + &2))
  end

  defp weight_sum({_, weights}) do
    Enum.reduce(weights, 0, fn {_, weight}, acc -> weight + acc end)
  end
end
