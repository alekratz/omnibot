defmodule Omnibot.Contrib.Wordbot do
  use Omnibot.Module.Base
  use Supervisor
  require Logger

  alias Omnibot.Contrib.Wordbot

  @default_config wordbot_source: "words.txt", wordbot_db: "wordbot.db", words_per_round: 300, hours_per_round: 5

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts[:cfg], opts)
  end

  @impl true
  def init(cfg) do
    children = [
      {Task.Supervisor, name: Omnibot.Contrib.Wordbot.Watchers, strategy: :one_for_one},
      Wordbot.Db.child_spec(cfg[:wordbot_db]),
      {Wordbot.Bot, cfg: cfg, name: Omnibot.Contrib.Wordbot.Bot},
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def on_msg(irc, msg), do: Wordbot.Bot.on_msg(irc, msg)

  def on_channel_msg(irc, channel, nick, msg), do: Wordbot.Bot.on_channel_msg(irc, channel, nick, msg)
end
