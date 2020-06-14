defmodule Omnibot.Core do
  use Omnibot.Module
  alias Omnibot.State

  @default_config [channels: :all]

  @impl true
  def on_join(irc, channel, nick) do
    cfg = State.cfg()
    if nick == cfg.nick do
      add_channel(channel)
      # Sync if we join a channel we shouldn't be in
      if !Enum.member?(State.all_channels(), channel),
        do: sync_channels(irc)
    end
  end

  @impl true
  def on_part(irc, channel, nick) do
    cfg = State.cfg()
    if nick == cfg.nick do
      remove_channel(channel)
      # Sync if we join a channel we forcibly part a channel we shouldn't leave
      if Enum.member?(State.all_channels(), channel),
        do: sync_channels(irc)
    end
  end

  @impl true
  def on_kick(irc, channel, _nick, target) do
    cfg = State.cfg()
    if target == cfg.nick do
      remove_channel(channel)
      # Generally, being kicked is not intentionally leaving a channel, so always sync here
      sync_channels(irc)
    end
  end

  @impl true
  def on_msg(irc, msg) do
    case String.upcase(msg.command) do
      "001" -> sync_channels(irc)
      "PING" -> Irc.send_msg(irc, "PONG", msg.params)
      _ -> route_msg(irc, msg)
    end
  end

  @impl true
  def on_init(_cfg) do
    MapSet.new()
  end

  defp sync_channels(irc) do
    desired = MapSet.new(State.all_channels())
    present = state()

    to_join = MapSet.difference(desired, present)
      |> MapSet.to_list()
    to_part = MapSet.difference(present, desired)
      |> MapSet.to_list()

    Enum.each(to_join, fn channel -> Irc.join(irc, channel) end)
    Enum.each(to_part, fn channel -> Irc.part(irc, channel) end)
  end

  defp add_channel(channel) do
    update_state(fn state -> MapSet.put(state, channel) end)
  end
  
  defp remove_channel(channel) do
    update_state(fn state -> MapSet.delete(state, channel) end)
  end
end

