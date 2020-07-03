defmodule Omnibot.Plugin.Meta do
  defmodule Hooks do
    defmacro __before_compile(_env) do
      quote do
        def children(_cfg), do: []
      end
    end
  end

  defmacro __using__([]) do
    quote do
      use Omnibot.Plugin.Base
      use Supervisor

      @behaviour Omnibot.Plugin.Meta

      ## Client API

      def start_link(opts) do
        Supervisor.start_link(opts)
      end

      ## Server callbacks
      def init(opts) do
        cfg = opts[:cfg]
        children = children(cfg)
        Supervisor.init(children, opts)
      end

      defoverridable Omnibot.Plugin.Meta

      @before_compile Omnibot.Plugin.Meta.Hooks
    end
  end

  @callback children(cfg :: any) :: [{atom(), [{atom(), any}]}]
end
