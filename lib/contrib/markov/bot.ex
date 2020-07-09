defmodule Omnibot.Contrib.Markov.Bot do
  use Omnibot.Plugin
  alias Omnibot.Contrib.Markov.Chain

  @impl true
  def on_init(_cfg) do
    # Create the markov database
    path = String.to_atom(cfg()[:path])
    {:ok, db} = :dets.open_file(path, [:named_table])
    chains = :ets.new(:markov_chains, [:public])
    :dets.to_ets(db, chains)
    :dets.close(db)
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

  def save_chains() do
    
  end
end
