defmodule Omnibot.UtilTest do
  use ExUnit.Case, async: true
  alias Omnibot.Util

  test "string_empty?" do
    assert Util.string_empty?("")
    assert !Util.string_empty?("asdf")
  end

  test "string_or_nil" do
    assert Util.string_or_nil("") == nil
    assert Util.string_or_nil("asdf") == "asdf"
  end

  test "pad_trailing" do
    assert Util.pad_trailing([1, 2, 3, 4], nil, 7) == [1, 2, 3, 4, nil, nil, nil]
    assert Util.pad_trailing([1, 2, 3, 4], nil, 6) == [1, 2, 3, 4, nil, nil]
    assert Util.pad_trailing([1, 2, 3, 4], nil, 5) == [1, 2, 3, 4, nil]
    assert Util.pad_trailing([1, 2, 3, 4], nil, 4) == [1, 2, 3, 4]
    assert Util.pad_trailing([1, 2, 3, 4], nil, 3) == [1, 2, 3, 4]
    assert Util.pad_trailing([1, 2, 3, 4], nil, 2) == [1, 2, 3, 4]
    assert Util.pad_trailing([1, 2, 3, 4], nil, 1) == [1, 2, 3, 4]
  end
end
