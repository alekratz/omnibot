defmodule MarkovChainTest do
  use ExUnit.Case
  alias Omnibot.Contrib.Markov.Chain

  test "chain train works correctly" do
    chain = %Chain {order: 2}
            |> Chain.train(~w(foo bar baz))
    assert chain.chain == [
      {["bar", "baz"], %{nil => 1}},
      {["foo", "bar"], %{"baz" => 1}},
    ]
  end

  test "chain add_weight works correctly" do
    chain = %Chain {order: 2}
            |> Chain.add_weight(["foo", "bar"], "baz")
    assert chain.chain == [
      {["foo", "bar"], %{"baz" => 1}}
    ]

    chain = chain |> Chain.add_weight(["foo", "bar"], "baz", 2)

    assert chain.chain == [
      {["foo", "bar"], %{"baz" => 3}}
    ]

    chain = chain |> Chain.add_weight(["foo", "bar"], "qux")

    assert chain.chain == [
      {["foo", "bar"], %{"baz" => 3, "qux" => 1}}
    ]
  end
end
