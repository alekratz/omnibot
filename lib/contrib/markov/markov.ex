defmodule Omnibot.Contrib.Markov do
  use Omnibot.Plugin.Supervisor
  alias Omnibot.Contrib.Markov.Chain
  require Logger

  @default_config path: "markov", order: 2, save_every: 5 * 60

  @impl true
  def children(cfg, _state) do
    [{Task, fn ->
      Stream.timer(cfg[:save_every] * 1000)
      |> Stream.cycle()
      |> Stream.each(fn _ -> save_chains() end)
      |> Stream.run()
    end}]
  end

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
    # TODO
    Logger.info("Saved markov chains")
  end
end
