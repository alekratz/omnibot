defmodule Omnibot.Contrib.Markov do
  use Omnibot.Plugin.Base
  alias Omnibot.Contrib.Markov
  use Supervisor

  @default_config path: "markov", order: 2, save_every: 5 * 60

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts[:cfg], opts)
  end

  @impl true
  def init(cfg) do
    children = [
      {Markov.Bot, cfg: cfg, name: Omnibot.Contrib.Markov.Bot},
      {Task, fn -> save_loop(cfg) end}
    ]
    Supervisor.init(children, strategy: :one_for_all)
  end

  defp save_loop(cfg) do
    save_every = cfg[:save_every]
    Process.sleep(save_every * 1000)
    Markov.Bot.save_chains()
  end

  @impl true
  def on_msg(irc, msg), do: Markov.Bot.on_msg(irc, msg)

  @impl true
  def on_channel_msg(irc, channel, nick, msg), do: Markov.Bot.on_channel_msg(irc, channel, nick, msg)
end
