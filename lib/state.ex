defmodule Omnibot.State do
  use GenServer

  @enforce_keys [:cfg]
  defstruct [:cfg, channels: MapSet.new(), module_map: %{}]

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

  @doc "Adds a loaded module to the default state."
  def add_loaded_module(module), do: add_loaded_module(__MODULE__, module)

  @doc "Adds a loaded module to the given state."
  def add_loaded_module(state, {module, cfg}), do: GenServer.cast(state, {:add_loaded_module, {module, cfg}})

  @doc "Adds a loaded module to the given state."
  def add_loaded_module(state, module), do: add_loaded_module(state, {module, []})

  @doc "Gets all loaded modules from the default state."
  def loaded_modules(), do: loaded_modules(__MODULE__)

  @doc "Gets all loaded modules from the given state."
  def loaded_modules(state), do: GenServer.call(state, :loaded_modules)

  def all_channels(), do: all_channels(__MODULE__)

  def all_channels(state) do
    loaded_modules(state) |> Enum.flat_map(
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

  def channel_modules(channel), do: channel_modules(__MODULE__, channel)

  @doc ~S"""
  Gets a list of all `{module, mod_cfg}` from the given State that are both
  loaded, and listening to the given channel.
  """
  def channel_modules(state, channel) do
    loaded_modules(state) |> Enum.filter(
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
  def handle_call(:loaded_modules, _from, state) do
    {:reply, state.module_map, state}
  end

  @impl true
  def handle_cast({:add_loaded_module, {module, cfg}}, state) do
    state = %{state | module_map: Map.put(state.module_map, module, cfg)}
    {:noreply, state}
  end
end
