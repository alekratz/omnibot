defmodule Omnibot.Contrib.Markov do
  use Omnibot.Plugin

  alias Omnibot.Contrib.Markov.Chain

  @default_config path: :"wordbot.ets", order: 2

  @impl true
  def on_init(cfg) do
    # Create the markov database
    path = if is_atom(cfg[:path]),
      do: cfg[:path],
      else: String.to_atom(cfg[:path])
    {:ok, db} = :dets.open_file(path)
    db
  end

  @impl true
  def on_channel_msg(_irc, _channel, _nick, msg) do
    _words = String.split(msg, ~r/\s+/)
  end
end
