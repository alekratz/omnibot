defmodule Omnibot.Plugin do
  @default_opts [include_base: true, opts: [strategy: :one_for_one]]

  defmodule CfgState do
    use Agent

    def start_link(opts) do
      {cfg, opts} = Keyword.pop(opts, :cfg)
      {state, opts} = Keyword.pop(opts, :state, nil)
      Agent.start_link(fn -> {cfg, state} end, opts)
    end

    def cfg(pid), do: Agent.get(pid, fn {cfg, _} -> cfg end)

    def state(pid), do: Agent.get(pid, fn {_, state} -> state end)

    def update_state(pid, fun, timeout \\ 5000),
      do: Agent.update(pid, &{&1, apply(fun, [&1])}, timeout)
  end

  defmacro __using__(opts) do
    opts = opts ++ @default_opts

    quote do
      use Supervisor
      use Omnibot.Plugin.Base

      ## Client API

      def start_link(opts) do
        Supervisor.start_link(__MODULE__, {opts[:cfg], opts[:state]}, opts)
      end

      def cfg() do
        Omnibot.Plugin.CfgState.cfg(__MODULE__.CfgState)
      end

      def state() do
        Omnibot.Plugin.CfgState.state(__MODULE__.CfgState)
      end

      def update_state(fun) do
        Omnibot.Plugin.CfgState.update_state(__MODULE__.CfgState, fun)
      end

      @impl Omnibot.Plugin.Base
      def handle_msg(irc, msg) do
        GenServer.cast(__MODULE__, {:handle_msg, irc, msg})
      end

      @impl Omnibot.Plugin
      def children(_cfg, _state), do: []

      ## Server callbacks

      @impl Supervisor
      def init({cfg, state}) do
        base_children = [
          {Omnibot.Plugin.CfgState, cfg: cfg, state: state, name: __MODULE__.CfgState},
        ]
        children = 
          (if unquote(opts[:include_base]), do: base_children, else: []) ++ children(cfg, state)
        Supervisor.init(children, unquote(opts[:opts]))
      end

      def handle_cast({:handle_msg, irc, msg}, state) do
        on_msg(irc, msg)
        {:noreply, state}
      end

      @behaviour Omnibot.Plugin
      defoverridable Omnibot.Plugin
    end
  end

  @callback children(cfg :: [atom: any], state :: any) :: [atom | {atom, [atom: any]} | {atom, any, [atom: any]}]
end
