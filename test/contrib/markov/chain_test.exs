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

    chain = chain |> Chain.train(~w(foo bar baz))

    assert chain.chain == [
      {["bar", "baz"], %{nil => 2}},
      {["foo", "bar"], %{"baz" => 2}},
    ]

    chain = chain |> Chain.train(~w(baz bar foo))

    assert chain.chain == [
      {["bar", "foo"], %{nil => 1}},
      {["baz", "bar"], %{"foo" => 1}},
      {["bar", "baz"], %{nil => 2}},
      {["foo", "bar"], %{"baz" => 2}},
    ]

    chain = chain |> Chain.train(~w(a b c))
    assert chain.chain == [
      {["b", "c"], %{nil => 1}},
      {["a", "b"], %{"c" => 1}},
      {["bar", "foo"], %{nil => 1}},
      {["baz", "bar"], %{"foo" => 1}},
      {["bar", "baz"], %{nil => 2}},
      {["foo", "bar"], %{"baz" => 2}},
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

    chain = chain |> Chain.add_weight(["bar", "baz"], "qux")
    assert chain.chain == [
      {["bar", "baz"], %{"qux" => 1}},
      {["foo", "bar"], %{"baz" => 3, "qux" => 1}},
    ]

    chain = chain |> Chain.add_weight(["bar", "baz"], nil)
    assert chain.chain == [
      {["bar", "baz"], %{"qux" => 1, nil => 1}},
      {["foo", "bar"], %{"baz" => 3, "qux" => 1}},
    ]
  end
end
