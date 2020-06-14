defmodule Omnibot.Module do
  defmacro __using__([]) do
    quote do
      use Omnibot.Module.Base
      use Omnibot.Module.Agent
    end
  end
end
