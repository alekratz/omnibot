defmodule Omnibot.Core do
  require Logger
  use Omnibot.Plugin
  alias Omnibot.{Config, Irc, Util}

  @default_config quit_after: 180, ping_after: 60, channels: :all
  
  ## Client API

  defp add_channel(channel) do
    update_state(fn cfg = %{channels: channels} -> %{cfg | channels: MapSet.put(channels, channel)} end)
  end
  
  defp remove_channel(channel) do
    update_state(fn cfg = %{channels: channels} -> %{cfg | channels: MapSet.delete(channels, channel)} end)
  end

  defp last_reply() do
    state().last_reply
  end

  defp update_last_reply(last_reply) do
    update_state(fn cfg -> %{cfg | last_reply: last_reply} end)
  end

  ## Server callbacks

  @impl true
  def children(_cfg) do
    [{Task.Supervisor, name: Omnibot.Core.PingWatchers}]
  end

  @impl true
  def on_connect(irc) do
    Logger.info("Starting ping watcher")
    Task.Supervisor.async(Omnibot.Core.PingWatchers, fn -> ping_watcher(irc) end)
  end

  @impl true
  def on_join(irc, channel, nick) do
    cfg = Irc.cfg(irc)
    if nick == cfg.nick do
      add_channel(channel)
      # Sync if we join a channel we shouldn't be in
      if channel in Config.all_channels(cfg),
        do: sync_channels(irc)
    end
  end

  @impl true
  def on_part(irc, channel, nick) do
    cfg = Irc.cfg(irc)
    if nick == cfg.nick do
      remove_channel(channel)
      # Sync if we join a channel we forcibly part a channel we shouldn't leave
      if channel in Config.all_channels(cfg),
        do: sync_channels(irc)
    end
  end

  @impl true
  def on_kick(irc, channel, _nick, target) do
    cfg = Irc.cfg(irc)
    if target == cfg.nick do
      remove_channel(channel)
      # Generally, being kicked is not intentionally leaving a channel, so always sync here
      sync_channels(irc)
    end
  end

  @impl true
  def on_msg(irc, :connect) do
    on_connect(irc)
  end

  @impl true
  def on_msg(irc, msg) do
    case String.upcase(msg.command) do
      "001" -> sync_channels(irc)
      "PING" ->
        Irc.send_msg(irc, "PONG", msg.params)
        update_last_reply(Util.now_unix())
      _ -> route_msg(irc, msg)
    end
    update_last_reply(Util.now_unix())
  end

  @impl true
  def on_init(_cfg) do
    %{channels: MapSet.new(), last_reply: Util.now_unix()}
  end

  defp sync_channels(irc) do
    cfg = Irc.cfg(irc)
    desired = MapSet.new(Config.all_channels(cfg))
    present = state().channels

    to_join = MapSet.difference(desired, present)
      |> MapSet.to_list()
    to_part = MapSet.difference(present, desired)
      |> MapSet.to_list()

    Enum.each(to_join, fn channel -> Irc.join(irc, channel) end)
    Enum.each(to_part, fn channel -> Irc.part(irc, channel) end)
  end

  ## Ping watcher worker
  
  defp ping_watcher(irc) do
    since_reply = Util.now_unix() - last_reply()
    ping_after = cfg(:ping_after)
    quit_after = cfg(:quit_after)
    cond do
      # Kill IRC instance
      since_reply >= quit_after ->
        Logger.error("IRC has not replied in #{quit_after}")
        Process.exit(irc, :ping_timeout)

      # Send ping message
        # use == since >= will ping each time until a reply is received
      since_reply == ping_after -> 
        update_last_reply(Util.now_unix())
        Irc.send_msg(irc, "PING", "omnibot")

      true -> nil
    end
    Process.sleep(1000)
    ping_watcher(irc)
  end
end

