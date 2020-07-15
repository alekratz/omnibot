defmodule Omnibot.Contrib.Markov do
  use Omnibot.Plugin
  alias Omnibot.{Contrib.Markov.Chain, Util}
  require Logger

  @default_config path: "markov.ets", order: 2, save_every: 5 * 60

  command "!markov", ["force"] do
    # Choose a random value from the sender
    Irc.send_to(irc, channel, "TODO")
  end

  command "!markov", ["all"] do
    Irc.send_to(irc, channel, "TODO")
  end

  command "!markov", ["status"] do
    Irc.send_to(irc, channel, "TODO")
  end

  @impl true
  def children(cfg) do
    [
      {Task, fn ->
        Stream.timer(cfg[:save_every] * 1000)
        |> Stream.cycle()
        |> Stream.each(fn _ -> save_chains() end)
        |> Stream.run()
      end}
    ]
  end

  @impl true
  def on_init(_cfg) do
    # Create the markov database
    path = String.to_atom(cfg()[:path])
    {:ok, db} = :dets.open_file(path, [])
    chains = :ets.new(:markov_chains, [:named_table, :public])
    :dets.to_ets(db, chains)
    :ok = :dets.close(db)
    chains
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
      _old_chain -> :ets.insert(db, {{channel, user}, chain})
    end
  end

  defp create_user_chain(channel, user) do
    true = update_user_chain(channel, user, %Chain{order: cfg()[:order]})
    user_chain(channel, user)
  end

  def save_chains() do
    start = Util.now_unix()
    Logger.debug("Saving markov chains")

    {:ok, db} = :dets.open_file(cfg()[:path], [])
    :ets.to_dets(state(), db)
    :ok = :dets.close(db)

    stop = Util.now_unix()
    Logger.info("Saved markov chains in #{stop - start} seconds")
  end
end
