defmodule Omnibot.Plugin.Agent do
  defmacro __using__([]) do
    quote do
      alias Omnibot.Plugin
      use Agent

      def start_link(opts) do
        cfg = opts[:cfg]
        state = opts[:state] || on_init(cfg)
        Plugin.Agent.start_link(cfg, state, opts)
      end

      def cfg, do: Plugin.Agent.cfg(__MODULE__)
      def state, do: Plugin.Agent.state(__MODULE__)

      def update_state(update, timeout \\ 5000),
        do: Plugin.Agent.update_state(__MODULE__, update, timeout)
    end
  end

  def start_link(cfg, state, opts) do
    Agent.start_link(fn -> {cfg, state} end, opts)
  end

  def cfg(agent) do
    Agent.get(agent, fn {cfg, _} -> cfg end)
  end

  def state(agent) do
    Agent.get(agent, fn {_, state} -> state end)
  end

  def update_state(agent, update, timeout \\ 5000) do
    Agent.update(
      agent,
      fn {cfg, state} -> {cfg, apply(update, [state])} end,
      timeout
    )
  end
end
