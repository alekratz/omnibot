defmodule Omnibot.Contrib.OnConnect do
  use Omnibot.Plugin.GenServer
  require Logger

  @default_config [channels: :all, commands: []]

  @impl true
  def on_msg(irc, msg) do
    if msg.command == "001" do
      Logger.debug("Got welcome message")
      cfg()[:commands]
      |> Enum.each(fn [cmd | params] -> Irc.send_msg(irc, cmd, params) end)
    end
  end
end
