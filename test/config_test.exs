defmodule ConfigTest do
  use ExUnit.Case

  alias Omnibot.Config

  test "config all_channels works correctly" do
    cfg = %Config {
      server: "test",
      modules: [
        {Test, channels: ["#foo", "#bar"]},
        {Test, channels: ["#foo"]},
        {Test, channels: ["#bar"]},
        {Test, channels: ["#baz"]},
      ]
    }

    channels = Config.all_channels(cfg)

    assert length(channels) == 3
    assert Enum.any?(channels, fn channel -> channel == "#foo" end)
    assert Enum.any?(channels, fn channel -> channel == "#bar" end)
    assert Enum.any?(channels, fn channel -> channel == "#baz" end)
  end
end
