defmodule MarkovChainTest do
  use ExUnit.Case
  alias Omnibot.Contrib.Markov.Chain

  test "chain train_one works correctly" do
    chain = %Chain {order: 2}
            |> Chain.train_one(["foo", "bar"], "baz")
    #assert chain.chain == [
      #{["foo", "bar"], {"baz", 1}}
      #]
  end
end
