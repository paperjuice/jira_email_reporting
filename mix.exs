defmodule EmailReport.MixProject do
  use Mix.Project

  def project do
    [
      app: :email_report,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison],
      mod: {EmailReport.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, ">=0.0.0"},
      {:plug, ">=0.0.0"},
      {:cowboy, ">=0.0.0"},
      {:poison, ">=0.0.0"},
      {:timex, ">=0.0.0"}
    ]
  end
end
