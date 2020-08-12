defmodule Omnibot.Core do
  require Logger
  use Omnibot.Plugin
  alias Omnibot.{Config, Irc, Util}

  @default_config ping_every: 60, ping_after: 60, channels: :all

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
        update_last_ping(Util.now_unix())
        update_last_pong(Util.now_unix()) # also update pong because we ponged
      "PONG" -> update_last_pong(Util.now_unix())
      _ -> route_msg(irc, msg)
    end
  end

  @impl true
  def on_init(_cfg) do
    %{channels: MapSet.new(), last_pong: Util.now_unix(), last_ping: Util.now_unix()}
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

  defp add_channel(channel) do
    update_state(fn cfg = %{channels: channels} -> %{cfg | channels: MapSet.put(channels, channel)} end)
  end
  
  defp remove_channel(channel) do
    update_state(fn cfg = %{channels: channels} -> %{cfg | channels: MapSet.delete(channels, channel)} end)
  end

  defp last_pong() do
    state().last_pong
  end

  defp update_last_pong(last_pong) do
    update_state(fn cfg -> %{cfg | last_pong: last_pong} end)
  end

  defp last_ping() do
    state().last_ping
  end

  defp update_last_ping(last_ping) do
    update_state(fn cfg -> %{cfg | last_ping: last_ping} end)
  end

  defp ping_watcher(irc) do
    since_pong = Util.now_unix() - last_pong()
    since_ping = Util.now_unix() - last_ping()
    ping_every = cfg(:ping_every)
    ping_after = cfg(:ping_after)
    cond do
      # Kill IRC instance
      since_pong >= (3 * ping_every) ->
        Logger.error("IRC has not replied in #{3 * ping_every}")
        Process.exit(irc, :ping_timeout)

      # Send ping message
      since_pong >= ping_every and ping_after >= since_ping ->
        Irc.send_msg(irc, "PING", "omnibot")

      true -> nil
    end
    Process.sleep(1000)
    ping_watcher(irc)
  end
end

