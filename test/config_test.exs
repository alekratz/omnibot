defmodule Omnibot.ConfigTest do
  use ExUnit.Case, async: true
  doctest Omnibot.Config
  alias Omnibot.Config

  test "channel_plugins works correctly" do
    cfg = %Config {
      server: "test",
      plugins: [
        {FooBar, channels: ["#foo", "#bar"]},
        {Foo, channels: ["#foo"]},
        {Bar, channels: ["#bar"]},
        {Baz, channels: ["#baz"]},
        {All, channels: :all},
      ]
    }

    plugins = Config.channel_plugins(cfg, "#foo")
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 3
    assert Enum.member?(plugins, FooBar)
    assert Enum.member?(plugins, Foo)
    assert Enum.member?(plugins, All)

    plugins = Config.channel_plugins(cfg, "#bar")
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 3
    assert Enum.member?(plugins, FooBar)
    assert Enum.member?(plugins, Bar)
    assert Enum.member?(plugins, All)

    plugins = Config.channel_plugins(cfg, "#baz")
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 2
    assert Enum.member?(plugins, Baz)
    assert Enum.member?(plugins, All)

    plugins = Config.channel_plugins(cfg, nil)
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 1
    assert Enum.member?(plugins, All)
  end

  test "all_channels works correctly" do
    cfg = %Config {
      server: "testing",
      plugins: [
        {FooBar, channels: ["#foo", "#bar"]},
        {Foo, channels: ["#foo"]},
        {Bar, channels: ["#bar"]},
        {Baz, channels: ["#baz"]},
        {All, channels: :all},
      ],
    }

    channels = Config.all_channels(cfg)

    assert length(channels) == 3
    assert Enum.member?(channels, "#foo")
    assert Enum.member?(channels, "#bar")
    assert Enum.member?(channels, "#baz")
  end
end
