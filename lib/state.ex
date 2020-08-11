defmodule Omnibot.State do

  @moduledoc ""

  use GenServer

  @enforce_keys [:cfg]
  defstruct [:cfg, channels: MapSet.new(), plugin_map: %{}]

  ## Client API

  @deprecated "Get rid of this"
  def start_link(opts) do
    cfg = opts[:cfg]
    GenServer.start_link(__MODULE__, %Omnibot.State{
      cfg: cfg
    }, opts)
  end

  @deprecated "Use Irc.cfg/1 instead"
  @doc "Gets the current configuration from the default State process."
  def cfg(), do: cfg(__MODULE__)

  @deprecated "Get rid of this"
  @doc "Gets the current configuration from the given State process."
  def cfg(state) do
    GenServer.call(state, :cfg)
  end

  @deprecated "Get rid of this"
  @doc "Adds a loaded plugin to the default state."
  def add_loaded_plugin(plugin), do: add_loaded_plugin(__MODULE__, plugin)

  @deprecated "Get rid of this"
  @doc "Adds a loaded plugin to the given state."
  def add_loaded_plugin(state, {plugin, cfg}), do: GenServer.cast(state, {:add_loaded_plugin, {plugin, cfg}})

  @deprecated "Get rid of this"
  @doc "Adds a loaded plugin to the given state."
  def add_loaded_plugin(state, plugin), do: add_loaded_plugin(state, {plugin, []})

  @deprecated "Get rid of this"
  @doc "Gets all loaded plugins from the default state."
  def loaded_plugins(), do: loaded_plugins(__MODULE__)

  @deprecated "Get rid of this"
  @doc "Gets all loaded plugins from the given state."
  def loaded_plugins(state), do: GenServer.call(state, :loaded_plugins)

  @deprecated "Get rid of this"
  def all_channels(), do: all_channels(__MODULE__)

  @deprecated "Get rid of this"
  def all_channels(state) do
    loaded_plugins(state) |> Enum.flat_map(
      fn {_, cfg} ->
        case cfg[:channels] do
          :all -> []
          nil -> []
          channels -> channels
        end
      end)
      |> MapSet.new()
      |> MapSet.to_list()
  end

  @deprecated "Get rid of this"
  def channel_plugins(channel), do: channel_plugins(__MODULE__, channel)

  @deprecated "Get rid of this"
  @doc ~S"""
  Gets a list of all `{plugin, plug_cfg}` from the given State that are both
  loaded, and listening to the given channel.
  """
  def channel_plugins(state, channel) do
    loaded_plugins(state) |> Enum.filter(
      fn {_, cfg} ->
        cfg[:channels] == :all or Enum.member?(cfg[:channels] || [], channel)
      end)
  end

  ## Server API

  @deprecated "Get rid of this"
  @impl true
  def init(state) do
    {:ok, state}
  end

  @deprecated "Get rid of this"
  @impl true
  def handle_call(:cfg, _from, state) do
    {:reply, state.cfg, state}
  end

  @deprecated "Get rid of this"
  @impl true
  def handle_call(:loaded_plugins, _from, state) do
    {:reply, state.plugin_map, state}
  end

  @deprecated "Get rid of this"
  @impl true
  def handle_cast({:add_loaded_plugin, {plugin, cfg}}, state) do
    state = %{state | plugin_map: Map.put(state.plugin_map, plugin, cfg)}
    {:noreply, state}
  end
end
