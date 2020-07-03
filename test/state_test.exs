defmodule StateTest do
  use ExUnit.Case

  alias Omnibot.State

  setup do
    state = start_supervised!(State)
    {:ok, state: state}
  end

  test "state channel_plugins works correctly", %{state: state} do
    plugins = [
      {FooBar, channels: ["#foo", "#bar"]},
      {Foo, channels: ["#foo"]},
      {Bar, channels: ["#bar"]},
      {Baz, channels: ["#baz"]},
      {All, channels: :all},
    ]

    plugins |> Enum.each(fn plugin -> State.add_loaded_plugin(state, plugin) end)

    plugins = State.channel_plugins(state, "#foo")
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 3
    assert Enum.member?(plugins, FooBar)
    assert Enum.member?(plugins, Foo)
    assert Enum.member?(plugins, All)

    plugins = State.channel_plugins(state, "#bar")
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 3
    assert Enum.member?(plugins, FooBar)
    assert Enum.member?(plugins, Bar)
    assert Enum.member?(plugins, All)

    plugins = State.channel_plugins(state, "#baz")
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 2
    assert Enum.member?(plugins, Baz)
    assert Enum.member?(plugins, All)

    plugins = State.channel_plugins(state, nil)
              |> Enum.map(fn {plugin, _} -> plugin end)
    assert length(plugins) == 1
    assert Enum.member?(plugins, All)
  end

  test "state all_channels works correctly", %{state: state} do
    plugins = [
      {FooBar, channels: ["#foo", "#bar"]},
      {Foo, channels: ["#foo"]},
      {Bar, channels: ["#bar"]},
      {Baz, channels: ["#baz"]},
      {All, channels: :all},
    ]

    plugins |> Enum.each(fn plugin -> State.add_loaded_plugin(state, plugin) end)
    channels = State.all_channels(state)

    assert length(channels) == 3
    assert Enum.member?(channels, "#foo")
    assert Enum.member?(channels, "#bar")
    assert Enum.member?(channels, "#baz")
  end
end
