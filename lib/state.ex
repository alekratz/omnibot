defmodule Omnibot.State do
  use GenServer

  @enforce_keys [:cfg]
  defstruct [:cfg, channels: MapSet.new()]

  ## Client API

  def start_link(opts) do
    cfg = opts[:cfg]
    GenServer.start_link(__MODULE__, %Omnibot.State{
      cfg: cfg
    }, opts)
  end

  @doc "Gets the current configuration from the default State process."
  def cfg(), do: cfg(__MODULE__)

  @doc "Gets the current configuration from the given State process."
  def cfg(state) do
    GenServer.call(state, :cfg)
  end

  @doc "Gets all channels that the bot is present in from the default State process."
  def channels(), do: channels(__MODULE__)

  @doc "Gets all channels that the bot is present in from the given State process."
  def channels(state) do
    GenServer.call(state, :channels)
  end
  
  @doc "Adds a channel to the list of joined channels of the default State process, if it is not already present."
  def add_channel(channel), do: add_channel(__MODULE__, channel)

  @doc "Adds a channel to the list of joined channels of the given State process, if it is not already present."
  def add_channel(state, channel) do
    GenServer.cast(state, {:add_channel, channel})
  end

  @doc "Removes a channel from the list of joined channels of the default State process, if it exists."
  def remove_channel(channel), do: remove_channel(__MODULE__, channel)

  @doc "Removes a channel from the list of joined channels of the given State process, if it exists."
  def remove_channel(state, channel) do
    GenServer.cast(state, {:remove_channel, channel})
  end

  ## Server API

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:cfg, _from, state) do
    {:reply, state.cfg, state}
  end

  @impl true
  def handle_call(:channels, _from, state) do
    {:reply, state.channels, state}
  end
  
  @impl true
  def handle_cast({:add_channel, channel}, state) do
    {:noreply, %{state | channels: state.channels |> MapSet.put(channel)}}
  end

  @impl true
  def handle_cast({:remove_channel, channel}, state) do
    {:noreply, %{state | channels: state.channels |> MapSet.delete(channel)}}
  end
end
