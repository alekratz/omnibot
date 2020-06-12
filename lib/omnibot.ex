defmodule Omnibot do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Omnibot.Supervisor.start_link(name: Omnibot.Supervisor)
  end
end
