defmodule EslNews.MixProject do
  use Mix.Project

  def project do
    [
      app: :esl_news,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "ESL News",
      source_url: "https://github.com/sdrew/esl-news",
      homepage_url: "https://github.com/sdrew/esl-news",
      docs: [
        main: "EslNews",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mnesia],
      mod: {EslNews.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.9"},
      {:credo, "~> 1.6", only: [:dev, :test]},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.3.0"},
      {:socket, "~> 0.3.13", only: [:test]},
      {:tesla, "~> 1.4"}
    ]
  end
end
