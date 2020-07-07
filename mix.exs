defmodule Omnibot.MixProject do
  use Mix.Project

  def project do
    [
      app: :omnibot,
      version: "0.1.0",
      elixir: "~> 1.7",
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
    # TODO : figure out how to make contrib modules optional (umbrella project?) and enable specific requirements
    [
      {:tesla, "~> 1.3.0"},     # Used by Omnibot.Contrib.Linkbot
      {:meeseeks, "~> 0.15.1"}, # Used by Omnibot.Contrib.Linkbot
      {:sqlitex, "~> 1.7"},     # Used by Omnibot.Contrib.Wordbot
    ]
  end
end
