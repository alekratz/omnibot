defmodule Omnibot.Plugin.Supervisor do
  use Supervisor

  def start_link(opts) do
    {plugin, opts} = Keyword.pop(opts, :plugin)
    {cfg, opts} = Keyword.pop(opts, :cfg)
    start_link(plugin, cfg, opts)
  end

  def start_link(plugin, cfg, opts) when is_atom(plugin) do
    Supervisor.start_link(__MODULE__, {plugin, cfg}, opts)
  end

  def child_spec(arg) do
    id = Module.concat(arg[:plugin], Plugin.Supervisor)
    %{
      id: id,
      start: {__MODULE__, :start_link, [arg]},
    }
  end

  @impl true
  def init({plugin, cfg}) when is_atom(plugin) do
    children = plugin.plugin_children(cfg)
    Supervisor.init(children, strategy: :one_for_one)
  end
end
