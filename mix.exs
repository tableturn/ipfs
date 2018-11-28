defmodule IPFS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ipfs,
      version: "0.1.5",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "IPFS",
      source_url: "https://github.com/tableturn/ipfs",
      homepage_url: "https://github.com/tableturn/ipfs",
      dialyzer: [plt_add_deps: :project],
      docs: [extras: ~w(README.md)],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env_for(:test, ~w(
        coveralls coveralls.detail coveralls.html coveralls.json coveralls.post
        vcr.delete vcr.check vcr.show
      )),
      package: package(),
      description: "A wrapper around the IPFS and IPFS Cluster APIs."
    ]
  end

  def application do
    [extra_applications: [:logger, :httpoison]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Dev and Test only.
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      # Dev only.
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
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

  defp package do
    [
      name: "ipfs",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Pierre Martin"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/tableturn/ipfs"}
    ]
  end
end
