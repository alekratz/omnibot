alias Omnibot.Util

defmodule Omnibot.UtilTest do
  use ExUnit.Case

  test "string_empty?" do
    assert Util.string_empty?("")
    assert !Util.string_empty?("asdf")
  end

  test "string_or_nil" do
    assert Util.string_or_nil("") == nil
    assert Util.string_or_nil("asdf") == "asdf"
  end
end
