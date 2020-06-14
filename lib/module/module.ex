defmodule Omnibot.Module do
  defmacro __using__([]) do
    quote do
      use Omnibot.Module.Base
      use Agent

      def start_link(opts) do
        cfg = opts[:cfg]
        Agent.start_link(fn -> {cfg, on_init(cfg)} end, opts ++ [name: __MODULE__])
      end

      def cfg do
        Agent.get(__MODULE__, fn {cfg, _} -> cfg end)
      end

      def state do
        Agent.get(__MODULE__, fn {_, state} -> state end)
      end

      def update_state(update, timeout \\ 5000) do
        Agent.update(
          __MODULE__,
          fn {cfg, state} -> {cfg, apply(update, [state])} end,
          timeout
        )
      end
    end
  end
end
