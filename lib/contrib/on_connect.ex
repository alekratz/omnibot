defmodule Omnibot.Contrib.OnConnect do
  use Omnibot.Plugin
  require Logger

  @default_config [channels: :all, commands: []]

  @impl true
  def on_msg(irc, %Irc.Msg {command: "001"}) do
    Logger.info("Running OnConnect commands")
    cfg()[:commands]
    |> Enum.each(fn [cmd | params] -> Irc.send_msg(irc, cmd, params) end)
  end
end
