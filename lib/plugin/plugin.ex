defmodule Omnibot.Plugin do
  @default_opts [include_base: true] # strategy: one_for_all

  defmodule CfgState do
    use Agent

    def start_link(opts) do
      {cfg, opts} = Keyword.pop(opts, :cfg)
      {state, opts} = Keyword.pop(opts, :state, nil)
      Agent.start_link(fn -> {cfg, state} end, opts)
    end

    def cfg(pid), do: Agent.get(pid, fn {cfg, _} -> cfg end)

    def state(pid), do: Agent.get(pid, fn {_, state} -> state end)

    def update_state(pid, fun, timeout \\ 5000) do
      Agent.update(pid, fn {cfg, state} -> {cfg, apply(fun, [state])} end, timeout)
    end
  end

  defmacro __using__(opts) do
    opts = opts ++ @default_opts

    quote generated: true do
      use GenServer
      use Omnibot.Plugin.Base

      ## Client API

      def start_link(opts) do
        {cfg, opts} = Keyword.pop(opts, :cfg)
        GenServer.start_link(__MODULE__, cfg, opts)
      end

      def cfg() when unquote(opts[:include_base]) do
        Omnibot.Plugin.CfgState.cfg(__MODULE__.CfgState)
      end

      def state() when unquote(opts[:include_base]) do
        Omnibot.Plugin.CfgState.state(__MODULE__.CfgState)
      end

      def update_state(fun) when unquote(opts[:include_base]) do
        Omnibot.Plugin.CfgState.update_state(__MODULE__.CfgState, fun)
      end

      @impl Omnibot.Plugin.Base
      def handle_msg(irc, msg) do
        GenServer.cast(__MODULE__, {:handle_msg, irc, msg})
      end

      ## Server callbacks

      @impl GenServer 
      def init(cfg) do
        # call on_init(cfg) for the plugin
        state = on_init(cfg)
        # If we know this plugin uses CfgState, then use that
        if unquote(opts[:include_base]) do
          Omnibot.Plugin.CfgState.update_state(__MODULE__.CfgState, fn _ -> state end)
        end
        {:ok, nil}
      end

      @impl GenServer
      def handle_cast({:handle_msg, irc, msg}, state) do
        on_msg(irc, msg)
        {:noreply, state}
      end

      defp base_children_before(cfg) when unquote(opts[:include_base]) do
        [{Omnibot.Plugin.CfgState, cfg: cfg, name: __MODULE__.CfgState}]
      end

      defp base_children_after(cfg) when unquote(opts[:include_base]) do
        [{__MODULE__, cfg: cfg, name: __MODULE__}]
      end

      defp base_children_before(_cfg), do: []

      defp base_children_after(_cfg), do: []

      @impl Omnibot.Plugin
      def children(cfg), do: []

      def plugin_children(cfg), do: base_children_before(cfg) ++ children(cfg) ++ base_children_after(cfg)

      @behaviour Omnibot.Plugin
      defoverridable Omnibot.Plugin
    end
  end

  @callback children(cfg :: [atom: any]) :: [atom | {atom, [atom: any]} | {atom, any, [atom: any]}]
end
