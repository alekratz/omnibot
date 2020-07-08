alias Omnibot.Util

defmodule Omnibot.UtilTest do
  use ExUnit.Case, async: true

  test "string_empty?" do
    assert Util.string_empty?("")
    assert !Util.string_empty?("asdf")
  end

  test "string_or_nil" do
    assert Util.string_or_nil("") == nil
    assert Util.string_or_nil("asdf") == "asdf"
  end

  test "binary_search" do
    indexes = 0..10 |> Enum.to_list()
    values = indexes |> Enum.map(&({&1, &1 * 2}))
    assert Enum.map(indexes, &(Util.binary_search(values, &1))) == values

    indexes = 0..101 |> Enum.to_list()
    values = indexes |> Enum.map(&({&1, &1 * 2}))
    assert Enum.map(indexes, &(Util.binary_search(values, &1))) == values

    values = [a: 15, b: 22, c: -1, d: 0]

    assert Util.binary_search(values, :a) == {0, 15}
    assert Util.binary_search(values, :b) == {1, 22}
    assert Util.binary_search(values, :c) == {2, -1}
    assert Util.binary_search(values, :d) == {3, 0}
  end
end
