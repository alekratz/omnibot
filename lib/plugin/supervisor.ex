defmodule Omnibot.Plugin.Supervisor do
  defmacro __using__(_opts) do
    quote do
      import Omnibot.Plugin.Supervisor
      alias Omnibot.Plugin
      use Supervisor

      @behaviour Omnibot.Plugin.Supervisor

      def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts[:cfg], opts)
      end

      def init(_cfg) do
        Supervisor.init(children(), strategy: :one_for_one)
      end

    end
  end

  @callback children() :: [any]
end

# TODO :
#   - figure out the best way to allow for including of supervisors and agents into a bot module
#     - have to `use Agent` both places, this is not optimal
#       - probably just lacks child_spec/1 ?
#       - Do away with actual Plugin.Agent set of functions (outside of macro),
#         and make it behaviours + `use Plugin.Agent` instead?
# Allow for ergonomic supervisor declarations, maybe like:
#
# Plugin.supervisor [
#   SomeAgent,
#   SomeGenSever,
#   SomeWorker,
# ], strategy: one_for_all
#
#
# And it implements all of the stuff for you? This may be too broad for how I'm doing things
#   - rename MODULES to PLUGINS
