defmodule Omnibot.Contrib.Markov.ChainServer do
  use GenServer
  alias Omnibot.Contrib.Markov
  require Logger

  ## Client API

  def start_link(opts) do
    {channel, opts} = Keyword.pop(opts, :channel)
    {user, opts} = Keyword.pop(opts, :user)

    GenServer.start_link(__MODULE__, {channel, user}, opts)
  end

  @compile :inline
  def user_path(channel, user), do: Path.join(channel_dir(channel), "#{user}.chain")

  @compile :inline
  def channel_dir(channel), do: Path.join(Markov.save_dir(), channel)

  def load(channel, user) when user != :all do
    with {:ok, contents} <- user_path(channel, user) |> File.read(),
         do: {:ok, :erlang.binary_to_term(contents)}
  end

  def save(server) do
    GenServer.call(server, :save)
  end

  def train(server, msg) do
    GenServer.call(server, {:train, msg})
  end

  def chain(server) do
    GenServer.call(server, :chain)
  end

  def channel(server) do
    GenServer.call(server, :channel)
  end

  def user(server) do
    GenServer.call(server, :user)
  end

  def generate(server) do
    GenServer.call(server, :generate)
  end

  def chain_sum(server) do
    GenServer.call(server, :chain_sum)
  end

  def reply_chance(server) do
    GenServer.call(server, :reply_chance)
  end

  def set_reply_chance(server, chance) do
    GenServer.cast(server, {:set_reply_chance, chance})
  end

  ## Server callbacks
  
  @impl true
  def init({channel, :all}) do
    Logger.debug("Creating allchain for channel #{channel}")

    chain = File.ls!(channel_dir(channel))
      |> Enum.map(&(Path.join(channel_dir(channel), &1) |> Markov.Chain.load!()))
      |> Markov.Chain.merge()
    {:ok, {chain, channel, :all}}
    # TODO: load allchain
    #chain = case load(channel, user) do
      #{:ok, chain} -> chain
      #{:error, _} -> %Markov.Chain{order: cfg()[:order]}
    #end
    #{:ok, {chain, channel, user}}
  end

  @impl true
  def init({channel, user}) do
    chain = case load(channel, user) do
      {:ok, chain} -> chain
      {:error, _} -> %Markov.Chain{order: Markov.cfg()[:order]}
    end
    {:ok, {chain, channel, user}}
  end

  @impl true
  def handle_call(:save, _from, state = {_chain, channel, :all}) do
    Logger.debug("Not saving :all chain for #{channel}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:save, _from, state = {chain, channel, user}) do
    File.mkdir_p!(channel_dir(channel))
    path = user_path(channel, user)
    Logger.debug("Saving chain for #{user} on #{channel} to #{path}")
    :ok = Markov.Chain.save!(chain, path)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:train, msg}, _from, {chain, channel, user}) do
    {:reply, :ok, {Markov.Chain.train(chain, msg), channel, user}}
  end

  @impl true
  def handle_call(:chain, _from, state = {chain, _channel, _user}) do
    {:reply, chain, state}
  end

  @impl true
  def handle_call(:channel, _from, state = {_chain, channel, _user}) do
    {:reply, channel, state}
  end

  @impl true
  def handle_call(:user, _from, state = {_chain, _channel, user}) do
    {:reply, user, state}
  end

  @impl true
  def handle_call(:generate, _from, state = {chain, _channel, _user}) do
    {:reply, Markov.Chain.generate(chain), state}
  end

  @impl true
  def handle_call(:chain_sum, _from, state = {chain, _channel, _user}) do
    {:reply, Markov.Chain.chain_sum(chain), state}
  end

  @impl true
  def handle_call(:reply_chance, _from, state = {chain, _channel, _user}) do
    {:reply, chain.reply_chance, state}
  end

  @impl true
  def handle_cast({:set_reply_chance, chance}, {chain, channel, user}) when is_float(chance) or chance == 0 do
    {:noreply, {%Markov.Chain{chain | reply_chance: chance}, channel, user}}
  end
end
