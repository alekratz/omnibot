defmodule Omnibot.Plugin.Supervisor do
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
        Omnibot.Plugin.Supervisor.CfgState.cfg(__MODULE__.CfgState)
      end

      def state() do
        Omnibot.Plugin.Supervisor.CfgState.state(__MODULE__.CfgState)
      end

      def update_state(fun) do
        Omnibot.Plugin.Supervisor.CfgState.update_state(__MODULE__.CfgState, fun)
      end

      ## Server callbacks

      @impl Supervisor
      def init({cfg, state}) do

        base_children = [
          {Omnibot.Plugin.Supervisor.CfgState, cfg: cfg, state: state, name: __MODULE__.CfgState},
        ]
        children = 
          (if unquote(opts[:include_base]), do: base_children, else: []) ++ children(cfg, state)
        Supervisor.init(children, unquote(opts[:opts]))
      end

      @behaviour Omnibot.Plugin.Supervisor
    end
  end

  @callback children(cfg :: [atom: any], state :: any) :: [atom | {atom, [atom: any]} | {atom, any, [atom: any]}]
end
