defmodule Omnibot.Irc do
  require Logger
  alias Omnibot.Irc.Msg
  alias Omnibot.Config
  use GenServer

  ## Client API

  def start_link(opts) do
    {cfg, opts} = Keyword.pop!(opts, :cfg)
    GenServer.start_link(__MODULE__, cfg, opts)
  end

  def send_msg(irc, msg) do
    GenServer.cast(irc, {:send_msg, msg})
  end

  def send_msg(irc, command, params) when is_list(params) do
    GenServer.cast(irc, {:send_msg, command, params})
  end

  def send_msg(irc, command, param), do: send_msg(irc, command, [param])

  def send_to(irc, channel, text), do: send_msg(irc, "PRIVMSG", [channel, text])

  def join(irc, channel), do: send_msg(irc, "JOIN", channel)

  def part(irc, channel), do: send_msg(irc, "PART", channel)

  def cfg(irc), do: GenServer.call(irc, :cfg)

  defp route_msg(irc, cfg, :connect) do
    handle_msg(irc, cfg.plugins, :connect)
  end

  defp route_msg(irc, cfg, msg) do
    plugins = Config.channel_plugins(cfg, Msg.channel(msg))
    handle_msg(irc, plugins, msg)
  end

  defp handle_msg(irc, plugins, msg) do
    Task.Supervisor.async_stream_nolink(
      Omnibot.RouterSupervisor,
      plugins,
      # Spin up tasks to handle messages in case handle_msg() hangs
      fn {plugin, _plug_cfg} -> plugin.handle_msg(irc, msg) end,
      timeout: 30_000,
      on_timeout: :kill_task
    ) |> Stream.run()
  end

  ## Server callbacks

  @impl true
  def init(cfg) do
    _ssl = cfg.ssl

    {:ok, socket} =
      :gen_tcp.connect(to_charlist(cfg.server), cfg.port, [:binary, active: false, packet: :line])

    # Wait for first message
    send_msg(self(), "NICK", cfg.nick)
    send_msg(self(), "USER", [cfg.user, "0", "*", cfg.real])
    :inet.setopts(socket, active: true)

    route_msg(self(), cfg, :connect)
    {:ok, {socket, cfg}}
  end

  defp write(socket, msg) do
    msg = String.Chars.to_string(msg)
    Logger.debug(">>> #{msg}")
    :gen_tcp.send(socket, "#{msg}\r\n")
  end

  @impl true
  def handle_cast({:send_msg, command, params}, state = {socket, cfg}) do
    msg = Config.msg(cfg, command, params)
    write(socket, msg)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_msg, msg}, state = {socket, _cfg}) do
    write(socket, msg)
    {:noreply, state}
  end

  @impl true
  def handle_call(:cfg, _from, state = {_socket, cfg}) do
    {:reply, cfg, state}
  end

  @impl true
  def handle_info({:tcp, _info_socket, line}, state = {_socket, cfg}) do
    Logger.debug(String.trim(line))
    msg = Msg.parse(line)

    # Send the message to the router
    route_msg(self(), cfg, msg)
    
    {:noreply, state}
  end
end
