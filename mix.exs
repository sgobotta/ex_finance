defmodule ExFinance.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_finance,
      version: File.read!("version.txt"),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # Docs
      name: "Finance Apps",
      source_url: "https://github.com/sgobotta/ex_finance",
      docs: [
        main: "ExFinance",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ExFinance.Application, []},
      extra_applications: [:ecto_enum, :logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "priv/repo/seeds", "test/support"]
  defp elixirc_paths(_), do: ["lib", "priv/repo/seeds"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      # Code quality and Testing
      {:credo, "~> 1.6.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.15", only: [:test]},
      {:git_hooks, "~> 0.7.3", only: [:dev], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:test], runtime: false},
      # Documentation
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      # Phoenix default apps
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:floki, ">= 0.30.0"},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},
      # Other
      {:decimal, "~> 2.0"},
      {:ecto_enum, "~> 1.4"},
      {:gen_stage, "~> 1.2"},
      {:off_broadway_redis_stream, "~> 0.5.0"},
      {:phoenix_inline_svg, "~> 1.4"},
      {:redix, "~> 1.2"},
      {:tzdata, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      # Run code checks
      check: [
        "check.format",
        "check.credo",
        "check.dialyzer"
      ],
      "check.format": ["format --check-formatted", "eslint"],
      "check.credo": ["credo --strict"],
      "check.dialyzer": ["dialyzer --format dialyxir"],
      eslint: ["cmd npm run eslint --prefix assets"],
      "eslint.fix": ["cmd npm run eslint-fix --prefix assets"],
      # Setup project
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      # Test
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      # Client setup
      "assets.setup": [
        "assets.install",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.install": ["cmd npm i --prefix assets"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "assets.install",
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
