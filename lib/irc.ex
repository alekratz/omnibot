# REWRITE
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

  def send_to(channel, text), do: send_to(__MODULE__, channel, text)
  def send_to(irc, channel, text), do: send_msg(irc, "PRIVMSG", [channel, text])

  def join(channel), do: join(__MODULE__, channel)
  def join(irc, channel), do: send_msg(irc, "JOIN", channel)

  def part(channel), do: part(__MODULE__, channel)
  def part(irc, channel), do: send_msg(irc, "PART", channel)

  def sync_channels(), do: sync_channels(__MODULE__)
  def sync_channels(irc), do: GenServer.cast(irc, :sync_channels)

  ## Server callbacks

  @impl true
  def init(:ok) do
    cfg = State.cfg()
    _ssl = cfg.ssl

    {:ok, socket} =
      :gen_tcp.connect(to_charlist(cfg.server), cfg.port, [:binary, active: false, packet: :line])

    # Wait for first message
    #{:ok, _} = :gen_tcp.recv(socket, 0)
    send_msg(self(), "NICK", cfg.nick)
    send_msg(self(), "USER", [cfg.user, "0", "*", cfg.real])
    :inet.setopts(socket, [active: true])

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
  def handle_cast({:tcp, line}, socket) do
    Logger.debug(line)
    {:noreply, socket}
  end

  @impl true
  def handle_cast(:sync_channels, socket) do
    cfg = State.cfg()
    desired = MapSet.new(Config.all_channels(cfg))
    present = MapSet.new(State.channels())
    to_join = MapSet.difference(desired, present)
      |> MapSet.to_list()
    to_part = MapSet.difference(present, desired)
      |> MapSet.to_list()

    Enum.each(to_join, fn channel -> join(self(), channel) end)
    Enum.each(to_part, fn channel -> part(self(), channel) end)

    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:tcp, _socket, line}, socket) do
    Logger.debug(String.trim(line))
    msg = Msg.parse(line)

    # Send the message to the router
    irc = self()
    {:ok, _task} = Task.Supervisor.start_child(
      Omnibot.RouterSupervisor,
      fn -> Omnibot.Router.route(irc, msg) end
    )
    {:noreply, socket}
  end
end
