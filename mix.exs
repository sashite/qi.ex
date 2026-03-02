defmodule Qi.MixProject do
  use Mix.Project

  @version "3.0.0"
  @source_url "https://github.com/sashite/qi.ex"

  def project do
    [
      app: :qi,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Qi",
      description: description(),
      package: package(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp description do
    "A minimal, format-agnostic library for representing positions " <>
      "in two-player, turn-based board games (chess, shogi, xiangqi, and variants)."
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Cyril Kato"]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false}
    ]
  end
end
