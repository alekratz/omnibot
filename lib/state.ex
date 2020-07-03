defmodule Omnibot.State do
  use GenServer

  @enforce_keys [:cfg]
  defstruct [:cfg, channels: MapSet.new(), plugin_map: %{}]

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

  @doc "Adds a loaded plugin to the default state."
  def add_loaded_plugin(plugin), do: add_loaded_plugin(__MODULE__, plugin)

  @doc "Adds a loaded plugin to the given state."
  def add_loaded_plugin(state, {plugin, cfg}), do: GenServer.cast(state, {:add_loaded_plugin, {plugin, cfg}})

  @doc "Adds a loaded plugin to the given state."
  def add_loaded_plugin(state, plugin), do: add_loaded_plugin(state, {plugin, []})

  @doc "Gets all loaded plugins from the default state."
  def loaded_plugins(), do: loaded_plugins(__MODULE__)

  @doc "Gets all loaded plugins from the given state."
  def loaded_plugins(state), do: GenServer.call(state, :loaded_plugins)

  def all_channels(), do: all_channels(__MODULE__)

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

  def channel_plugins(channel), do: channel_plugins(__MODULE__, channel)

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

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:cfg, _from, state) do
    {:reply, state.cfg, state}
  end

  @impl true
  def handle_call(:loaded_plugins, _from, state) do
    {:reply, state.plugin_map, state}
  end

  @impl true
  def handle_cast({:add_loaded_plugin, {plugin, cfg}}, state) do
    state = %{state | plugin_map: Map.put(state.plugin_map, plugin, cfg)}
    {:noreply, state}
  end
end
