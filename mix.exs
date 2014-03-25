defmodule Zorn.Mixfile do
  use Mix.Project

  def project do
    [ app: :zorn,
      version: "0.0.5",
      elixir: "~> 0.13.0-dev",
      deps: deps(Mix.env) ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  defp deps(:prod) do
    [ {:cowboy, github: "extend/cowboy"},
      {:plug, github: "elixir-lang/plug"},
      {:ecto, github: "elixir-lang/ecto"},
      {:postgrex, github: "ericmj/postgrex"},
      {:inflex, github: "nurugger07/inflex"} ]
  end

  defp deps(:test),
    do: deps(:prod) ++ [ {:json, github: "cblage/elixir-json"} ]

  defp deps(_),
    do: deps(:prod)
end
