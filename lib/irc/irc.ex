defmodule Omnibot.Irc do
  require Logger
  alias Omnibot.Irc.Msg
  alias Omnibot.{Config, State}
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def send_msg(irc, msg) do
    GenServer.cast(irc, {:send_msg, msg})
  end

  def send_msg(irc, command, params) when is_list(params) do
    cfg = State.cfg()
    GenServer.cast(irc, {:send_msg, Config.msg(cfg, command, params)})
  end

  def send_msg(irc, command, param), do: send_msg(irc, command, [param])

  def send_to(irc, channel, text), do: send_msg(irc, "PRIVMSG", [channel, text])

  def join(irc, channel), do: send_msg(irc, "JOIN", channel)

  def part(irc, channel), do: send_msg(irc, "PART", channel)

  defp route_msg(irc, msg) do
    plugins = Msg.channel(msg) |> State.channel_plugins()

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
  def init(:ok) do
    cfg = State.cfg()
    _ssl = cfg.ssl

    {:ok, socket} =
      :gen_tcp.connect(to_charlist(cfg.server), cfg.port, [:binary, active: false, packet: :line])

    # Wait for first message
    send_msg(self(), "NICK", cfg.nick)
    send_msg(self(), "USER", [cfg.user, "0", "*", cfg.real])
    :inet.setopts(socket, active: true)

    {:ok, socket}
  end

  defp write(socket, msg) do
    msg = String.Chars.to_string(msg)
    Logger.debug(">>> #{msg}")
    :gen_tcp.send(socket, "#{msg}\r\n")
  end

  @impl true
  def handle_cast({:send_msg, msg}, socket) do
    write(socket, msg)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:tcp, _socket, line}, socket) do
    Logger.debug(String.trim(line))
    msg = Msg.parse(line)

    # Send the message to the router
    if msg.prefix && (msg.prefix.nick != State.cfg().nick) do
      route_msg(self(), msg)
    end
    {:noreply, socket}
  end
end
