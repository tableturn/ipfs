defmodule IPFS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ipfs,
      version: "0.1.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "IPFS",
      source_url: "https://github.com/the-missing-link/ipfs",
      homepage_url: "https://github.com/the-missing-link/ipfs",
      docs: [extras: ~w(README.md)],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env_for(:test, ~w(
        coveralls coveralls.detail coveralls.html coveralls.json coveralls.post
        vcr.delete vcr.check vcr.show
      ))
    ]
  end

  def application do
    [extra_applications: [:logger, :httpoison]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Dev only.
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:credo, "~> 0.8", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false},
      # Test only.
      {:exvcr, "~> 0.10", only: :test},
      # All environments.
      {:poison, "~> 3.1"},
      {:httpoison, "~> 1.1"}
    ]
  end

  defp cli_env_for(env, tasks) do
    Enum.reduce(tasks, [], &Keyword.put(&2, :"#{&1}", env))
  end
end
