defmodule Omnibot.Contrib.Markov.ChainServer do
  use GenServer
  alias Omnibot.Contrib.Markov
  require Logger

  ## Client API

  def start_link(opts) do
    {cfg, opts} = Keyword.pop(opts, :cfg)
    {channel, opts} = Keyword.pop(opts, :channel)
    {user, opts} = Keyword.pop(opts, :user)

    chain = case load(channel, user) do
      {:ok, chain} -> chain
      {:error, _} -> %Markov.Chain{order: cfg[:order]}
    end
    GenServer.start_link(__MODULE__, {chain, channel, user}, opts)
  end

  @compile :inline
  def user_path(channel, user), do: Path.join(channel_dir(channel), "#{user}.chain")

  @compile :inline
  def channel_dir(channel), do: Path.join(Markov.save_dir(), channel)

  def load(channel, user) do
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

  ## Server callbacks

  @impl true
  def init({chain, channel, user}) do
    {:ok, {chain, channel, user}}
  end

  @impl true
  def handle_call(:save, _from, state = {chain, channel, user}) do
    File.mkdir_p!(channel_dir(channel))
    path = user_path(channel, user)
    Logger.debug("Saving chain for #{user} on #{channel} to #{path}")
    File.write!(path, :erlang.term_to_binary(chain))
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
end
