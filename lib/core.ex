defmodule Omnibot.Core do
  use Omnibot.Module
  alias Omnibot.State

  def on_join(irc, channel, nick) do
    cfg = State.cfg()
    if nick == cfg.nick do
      State.add_channel(channel)
      # Sync if we join a channel we shouldn't be in
      if !Enum.member?(State.all_channels(), channel),
        do: Irc.sync_channels(irc)
    end
  end

  def on_part(irc, channel, nick) do
    cfg = State.cfg()
    if nick == cfg.nick do
      State.remove_channel(channel)
      # Sync if we join a channel we forcibly part a channel we shouldn't leave
      if Enum.member?(State.all_channels(), channel),
        do: Irc.sync_channels(irc)
    end
  end

  def on_kick(irc, channel, _nick, target) do
    cfg = State.cfg()
    if target == cfg.nick do
      State.remove_channel(channel)
      # Generally, being kicked is not intentionally leaving a channel, so always sync here
      Irc.sync_channels(irc)
    end
  end

  @impl true
  def on_msg(irc, msg) do
    case String.upcase(msg.command) do
      "001" -> Irc.sync_channels(irc)
      "PING" -> Irc.send_msg(irc, "PONG", msg.params)
      _ -> route_msg(irc, msg)
    end
  end
end

