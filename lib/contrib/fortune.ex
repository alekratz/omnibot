defmodule Omnibot.Contrib.Fortune do
  use GenServer
  alias Omnibot.Irc
  require Logger

  @fortunes [
    "Reply hazy, try again",
    "Excellent Luck",
    "Good Luck",
    "Average Luck",
    "Bad Luck",
    "Good news will come to you by mail",
    "´_ゝ`",
    "ﾀ━━━━━━(ﾟ∀ﾟ)━━━━━━ !!!!",
    "You will meet a dark handsome stranger",
    "Better not tell you now",
    "Outlook good",
    "Very Bad Luck",
    "Godly Luck",
  ]

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:cfg], opts)
  end

  def privmsg(module, channel, nick, line) do
    GenServer.cast(module, {:privmsg, {channel, nick, line}})
  end

  ## Server callbacks

  @impl true
  def init(cfg) do
    #Logger.debug("Starting fortune module")
    #IO.inspect(self())
    {:ok, cfg}
  end

  @impl true
  def handle_call(:unload, _from, cfg) do
    Logger.info("Unloading")
    {:reply, :ok, cfg}
  end

  @impl true
  def handle_cast({:privmsg, {channel, nick, line}}, cfg) do
    if IO.inspect(line) == "!fortune" do
      fortune = Enum.random(@fortunes)
      reply = "#{nick}: #{fortune}"
      Irc.send_to(Irc, channel, reply)
    end

    {:noreply, cfg}
  end
end
