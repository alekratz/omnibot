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

    children = [
      {Task.Supervisor, name: Omnibot.RouterSupervisor, strategy: :one_for_one},
      {Omnibot.State, cfg: cfg, name: Omnibot.State},
      {Omnibot.Plugin.Supervisor, cfg: cfg, name: Omnibot.Plugin.Supervisor},
    ] ++ unless IEx.started?(),
      do: [{Omnibot.Irc, name: Omnibot.Irc}],
      else: []

    # TODO : how to handle config reloading?

    # :one_for_all here because the RouterSupervisor and IRC server are co-dependent
    Supervisor.init(children, strategy: :one_for_all)
  end
end

