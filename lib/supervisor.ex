defmodule Omnibot.Supervisor do
  @moduledoc false

  use Supervisor
  require IEx

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    
    {_, bindings} = System.get_env("OMNIBOT_CFG", "omnibot.exs")
                    |> Code.eval_file()
    cfg = bindings[:config]

    # TODO : move cfg to its own process so reloading it is as simple as killing the process
    children = [
      {Task.Supervisor, name: Omnibot.RouterSupervisor, strategy: :one_for_one},
      {Omnibot.State, cfg: cfg, name: Omnibot.State},
      {Omnibot.PluginManager, cfg: cfg, name: Omnibot.PluginManager},
    ] ++ unless IEx.started?(),
      do: [{Omnibot.Irc, cfg: cfg, name: Omnibot.Irc}],
      else: []

    # :one_for_all here because the RouterSupervisor and IRC server are co-dependent
    Supervisor.init(children, strategy: :one_for_all)
  end
end

