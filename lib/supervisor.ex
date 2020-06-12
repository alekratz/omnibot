defmodule Omnibot.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {_, bindings} = Code.eval_file("omnibot.exs")
    cfg = bindings[:config]

    children = [
      {Task.Supervisor, name: Omnibot.RouterSupervisor, strategy: :one_for_one},
      {Omnibot.State, cfg: cfg, name: Omnibot.State},
      {Omnibot.Irc, name: Omnibot.Irc},
      {Omnibot.ModuleSupervisor, cfg: cfg, name: Omnibot.ModuleSupervisor}
    ]

    # TODO : how to handle config reloading?
    # TODO : how to start up modules?

    # :one_for_all here because the RouterSupervisor and IRC server are co-dependent
    Supervisor.init(children, strategy: :one_for_all)
  end
end

