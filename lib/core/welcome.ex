defmodule Omnibot.Core.Welcome do
  use Omnibot.Module

  require Logger

  @impl true
  def on_msg(irc, _) do
    Logger.info("Syncing channels")
    Irc.sync_channels(irc)
  end
end
