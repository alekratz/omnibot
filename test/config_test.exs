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
        {Test, channels: :all},
      ]
    }

    channels = Config.all_channels(cfg)

    assert length(channels) == 3
    assert Enum.member?(channels, "#foo")
    assert Enum.member?(channels, "#bar")
    assert Enum.member?(channels, "#baz")
  end

  test "config channel_modules works correctly" do
    cfg = %Config {
      server: "test",
      modules: [
        {FooBar, channels: ["#foo", "#bar"]},
        {Foo, channels: ["#foo"]},
        {Bar, channels: ["#bar"]},
        {Baz, channels: ["#baz"]},
        {All, channels: :all},
      ]
    }

    modules = Config.channel_modules(cfg, "#foo")
              |> Enum.map(fn {module, _} -> module end)
    assert length(modules) == 3
    assert Enum.member?(modules, FooBar)
    assert Enum.member?(modules, Foo)
    assert Enum.member?(modules, All)

    modules = Config.channel_modules(cfg, "#bar")
              |> Enum.map(fn {module, _} -> module end)
    assert length(modules) == 3
    assert Enum.member?(modules, FooBar)
    assert Enum.member?(modules, Bar)
    assert Enum.member?(modules, All)

    modules = Config.channel_modules(cfg, "#baz")
              |> Enum.map(fn {module, _} -> module end)
    assert length(modules) == 2
    assert Enum.member?(modules, Baz)
    assert Enum.member?(modules, All)
  end
end
