defmodule Dissolver.Mixfile do
  use Mix.Project
  @version "0.9.1"

  def project do
    [
      app: :dissolver,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: path(Mix.env()),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Dissolver",
      docs: [
        source_ref: "v#{@version}",
        main: "Dissolver",
        extras: ["README.md"]
      ],
      source_url: "https://github.com/MorphicPro/dissolver",
      description: """
      Pagination for Ecto and Phoenix.
      """,
      preferred_cli_env: [credo: :test, "coveralls.html": :test, "gen.docs": :docs],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: application(Mix.env())]
  end

  defp application(:test), do: [:postgrex, :ecto, :logger]
  defp application(_), do: [:logger]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:phoenix_html, "~> 2.14"},
      {:plug, "~> 1.10"},
      {:ecto, "~> 3.4"},
      {:ecto_sql, "~> 3.4"},
      # Test dependencies
      {:postgrex, "~> 0.15", only: [:test]},
      {:credo, "~> 1.3", only: [:test]},
      {:excoveralls, "~> 0.12", only: [:test]},
      # Docs dependencies
      {:earmark, "~> 1.4", only: :docs},
      {:ex_doc, "~> 0.21", only: :docs},
      {:inch_ex, "~> 2.0", only: :docs}
    ]
  end

  defp path(:test) do
    ["lib", "test/support", "test/fixtures"]
  end

  defp path(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Josh Chernoff <jchernoff@morphic.pro>"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/MorphicPro/dissolver"},
      files:
        ~w(lib test config) ++
          ~w(CHANGELOG.md LICENSE.md mix.exs README.md)
    ]
  end

  def aliases do
    [
      "ecto.setup": ["ecto.create --quiet", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.setup", "test"],
      "gen.docs": ["docs -o docs"]
    ]
  end
end
