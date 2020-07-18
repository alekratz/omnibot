defmodule Omnibot.Contrib.Markov do
  use Omnibot.Plugin
  alias Omnibot.{Contrib.Markov.ChainServer, Util}
  require Logger

  @default_config save_dir: "markov", order: 2, save_every: 5 * 60

  @registry __MODULE__.Registry
  @supervisor __MODULE__.ChainSupervisor

  @impl true
  def children(cfg) do
    [
      {Task, fn -> Stream.timer(cfg[:save_every] * 1000)
        |> Stream.cycle()
        |> Stream.each(fn _ -> save_chains() end)
        |> Stream.run()
      end},
      {Registry, keys: :unique, name: @registry},
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one},
    ]
  end

  command "!markov", ["force"] do
    Irc.send_to(irc, channel, "TODO")
  end

  command "!markov", ["all"] do
    Irc.send_to(irc, channel, "TODO")
  end

  command "!markov", ["status"] do
    Irc.send_to(irc, channel, "TODO")
  end

  def save_dir() do
    cfg()[:save_dir]
  end

  @impl true
  def on_channel_msg(_irc, channel, nick, msg) do
    train(channel, nick, msg)
  end

  def train(channel, user, msg) do
    server = ensure_chain_server(channel, user)
    ChainServer.train(server, msg)
  end

  def ensure_chain(channel, user) do
    ensure_chain_server(channel, user)
    |> ChainServer.chain()
  end

  def user_chain(channel, user) do
    chain_server(channel, user) |> ChainServer.chain()
  end

  def chain_server(:all) do
    # See https://hexdocs.pm/elixir/Registry.html#select/2-examples to understand what the hell is going on here
    # (it just selects the PID of all chain_server processes)
    for {pid} <- Registry.select(@registry, [{{:_, :"$1", :_}, [], [{{:"$1"}}]}]),
      do: pid
  end

  def chain_server(channel, user) do
    case Registry.lookup(@registry, {channel, user}) do
      [] -> nil
      [{pid, _} | _] -> pid
    end
  end

  def ensure_chain_server(channel, user) do
    case chain_server(channel, user) do
      nil -> start_chain!(channel, user)
      pid -> pid
    end
  end

  defp start_chain!(channel, user) do
    {:ok, chain} = start_chain(channel, user)
    chain
  end

  defp start_chain(channel, user) do
    DynamicSupervisor.start_child(
      @supervisor,
      {ChainServer, cfg: cfg(), channel: channel, user: user, name: {:via, Registry, {@registry, {channel, user}}}}
    )
  end

  def save_chains() do
    start = Util.now_unix()
    Logger.debug("Saving markov chains")

    chain_server(:all) |> Enum.each(&ChainServer.save/1)

    stop = Util.now_unix()
    Logger.info("Saved markov chains in #{stop - start} seconds")
  end
end
