defmodule Omnibot.Plugin do
  defmacro __using__([]) do
    quote do
      use Omnibot.Plugin.Base
      use Omnibot.Plugin.Agent
    end
  end
end
