defmodule Omnibot.MixProject do
  use Mix.Project

  def project do
    [
      app: :omnibot,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Omnibot, []}
    ]
  end

  defp aliases do
    [
      c: ["clean", "compile --warnings-as-errors"],
      test: ["test --no-start"],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:tesla, "~> 1.3.0"}]
  end
end
