defmodule Omnibot.Core.Join do
  use Omnibot.Module
  alias Omnibot.State

  def on_join(channel, nick) do
    cfg = State.cfg()
    if nick == cfg.nick do
      State.add_channel(channel)
    end
  end
end
