defmodule Omnibot.Contrib.Markov do
  use Omnibot.Plugin

  alias Omnibot.Contrib.Markov.Chain

  @default_config path: "markov", order: 2

  @impl true
  def on_init(cfg) do
    # Create the markov database
    path = String.to_atom(cfg[:path])
    :ets.new(path, [:public])
  end

  @impl true
  def on_channel_msg(_irc, channel, nick, msg) do
    train(channel, nick, msg)
  end

  def train(channel, user, msg) do
    chain = (user_chain(channel, user) || create_user_chain(channel, user))
            |> Chain.train(msg)
    true = update_user_chain(channel, user, chain)
  end

  def user_chain(channel, user) do
    db = state()
    case :ets.lookup(db, {channel, user}) do
      [] -> nil
      [{{^channel, ^user}, chains}] -> chains
    end
  end

  def update_user_chain(channel, user, chain) do
    db = state()
    case user_chain(channel, user) do
      nil -> :ets.insert_new(db, {{channel, user}, chain})
      chain -> :ets.insert(db, {{channel, user}, chain})
    end
  end

  defp create_user_chain(channel, user) do
    true = update_user_chain(channel, user, %Chain{order: cfg()[:order]})
    user_chain(channel, user)
  end
end
