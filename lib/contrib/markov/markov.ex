defmodule Omnibot.Contrib.Markov do
  use Omnibot.Plugin
  alias Omnibot.{Contrib.Markov.ChainServer, Util}
  require Logger

  @default_config save_dir: "markov", order: 2, save_every: 5 * 60, ignore: [], max_reply_chance: 0.01

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
    do_markov_message(irc, channel, nick, nick)
  end

  # !markov emulate <name>, except it's !markov force <name>
  command "!markov", ["force", emulate] do
    do_markov_message(irc, channel, nick, emulate)
  end

  command "!markov", ["emulate", emulate] do
    do_markov_message(irc, channel, nick, emulate)
  end

  command "!markov", ["all"] do
    do_markov_message(irc, channel, nick, :all)
  end

  command "!markov", ["status"] do
    total = chain_server(channel, :all) |> ChainServer.chain_sum()
    value = chain_server(channel, nick) |> ChainServer.chain_sum()
    ratio = (value * 100) / total
    Irc.send_to(irc, channel, "#{nick}: You are worth #{ratio |> Float.round(4)}% of the channel")
  end

  command "!markov", ["chance"] do
    chance = reply_chance(channel, nick)
    Irc.send_to(irc, channel, "#{nick}: Your reply chance is #{chance}")
  end

  command "!markov", ["chance", chance] do
    {chance, ""} = Float.parse(chance)
    chance = min(chance, cfg()[:max_reply_chance]) |> max(0)
    chain_server(channel, nick) |> ChainServer.set_reply_chance(chance)
    Irc.send_to(irc, channel, "#{nick}: Your reply chance is now #{chance}")
  end

  defp do_markov_message(irc, channel, sender, user) do
    reply = chain_server(channel, user) |> ChainServer.generate()
    Irc.send_to(irc, channel, "#{sender}: #{reply}")
  end

  def save_dir() do
    cfg()[:save_dir]
  end

  def train(channel, user, msg) do
    server = chain_server(channel, user)
    ChainServer.train(server, msg)
  end

  def chain_servers() do
    # See https://hexdocs.pm/elixir/Registry.html#select/2-examples to understand what the hell is going on here
    # (it just selects the PID of all chain_server processes)
    for {pid} <- Registry.select(@registry, [{{:_, :"$1", :_}, [], [{{:"$1"}}]}]),
      do: pid
  end

  def chain_server(channel, user) do
    case Registry.lookup(@registry, {channel, user}) do
      [] -> start_chain_server!(channel, user)
      [{pid, _} | _] -> pid
    end
  end

  defp start_chain_server!(channel, user) do
    {:ok, chain} = start_chain_server(channel, user)
    chain
  end

  defp start_chain_server(channel, user) do
    DynamicSupervisor.start_child(
      @supervisor,
      {ChainServer, channel: channel, user: user, name: {:via, Registry, {@registry, {channel, user}}}}
    )
  end

  def save_chains() do
    start = Util.now_unix()
    Logger.debug("Saving markov chains")

    chain_servers() |> Enum.each(&ChainServer.save/1)

    stop = Util.now_unix()
    Logger.info("Saved markov chains in #{stop - start} seconds")
  end

  defp reply_chance(channel, user) do
    chain_server(channel, user) |> ChainServer.reply_chance()
  end

  @impl true
  def on_channel_msg(irc, channel, nick, msg) do
    # self-messages are already ignored, so just check the configured ignore-list
    filter = nick in cfg()[:ignore]
             || (String.trim(msg) |> String.starts_with?("!"))
    if !filter do
      train(channel, nick, msg)

      # Maybe send user a message
      if :rand.uniform() < reply_chance(channel, nick) do
        do_markov_message(irc, channel, nick, nick)
      end
    end
  end
end
