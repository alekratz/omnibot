defmodule StateTest do
  use ExUnit.Case

  alias Omnibot.State

  setup do
    state = start_supervised!(State)
    {:ok, state: state}
  end

  test "state channel_modules works correctly", %{state: state} do
    modules = [
      {FooBar, channels: ["#foo", "#bar"]},
      {Foo, channels: ["#foo"]},
      {Bar, channels: ["#bar"]},
      {Baz, channels: ["#baz"]},
      {All, channels: :all},
    ]

    modules |> Enum.each(fn module -> State.add_loaded_module(state, module) end)

    modules = State.channel_modules(state, "#foo")
              |> Enum.map(fn {module, _} -> module end)
    assert length(modules) == 3
    assert Enum.member?(modules, FooBar)
    assert Enum.member?(modules, Foo)
    assert Enum.member?(modules, All)

    modules = State.channel_modules(state, "#bar")
              |> Enum.map(fn {module, _} -> module end)
    assert length(modules) == 3
    assert Enum.member?(modules, FooBar)
    assert Enum.member?(modules, Bar)
    assert Enum.member?(modules, All)

    modules = State.channel_modules(state, "#baz")
              |> Enum.map(fn {module, _} -> module end)
    assert length(modules) == 2
    assert Enum.member?(modules, Baz)
    assert Enum.member?(modules, All)

    modules = State.channel_modules(state, nil)
              |> Enum.map(fn {module, _} -> module end)
    assert length(modules) == 1
    assert Enum.member?(modules, All)
  end

  test "state all_channels works correctly", %{state: state} do
    modules = [
      {FooBar, channels: ["#foo", "#bar"]},
      {Foo, channels: ["#foo"]},
      {Bar, channels: ["#bar"]},
      {Baz, channels: ["#baz"]},
      {All, channels: :all},
    ]

    modules |> Enum.each(fn module -> State.add_loaded_module(state, module) end)
    channels = State.all_channels(state)

    assert length(channels) == 3
    assert Enum.member?(channels, "#foo")
    assert Enum.member?(channels, "#bar")
    assert Enum.member?(channels, "#baz")
  end
end
