defmodule PetalPro.MixProject do
  use Mix.Project

  @version "2.2.0"

  def project do
    [
      app: :petal_pro,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        quality: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PetalPro.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  # Type `mix deps.update --all` to update deps (won't updated this file)
  # Type `mix hex.outdated` to see deps that can be updated
  defp deps do
    [
      # Phoenix base
      {:phoenix, "~> 1.7.17"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_psql_extras, "~> 0.7"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.1"},
      {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.1.5", app: false, compile: false, sparse: "optimized"},
      {:floki, ">= 0.34.3"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:swoosh, "~> 1.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.5"},
      {:dns_cluster, "~> 0.1.1"},

      # Emails
      {:phoenix_swoosh, "~> 1.0"},
      {:gen_smtp, "~> 1.2"},
      {:premailex, "~> 0.3.0"},
      {:email_checker, "~> 0.2.4"},
      {:money, "~> 1.12"},

      # Ecto querying / pagination
      {:query_builder, "~> 1.0"},
      {:flop, "~> 0.20"},
      {:typed_ecto_schema, "~> 0.4.1"},

      # Authentication
      {:bcrypt_elixir, "~> 3.0"},
      {:ueberauth, "<= 0.10.5 or ~> 0.10.7"},
      {:ueberauth_google, "~> 0.10"},
      {:ueberauth_github, "~> 0.7"},

      # API
      {:open_api_spex, "~> 3.18"},

      # TOTP (2FA)
      {:nimble_totp, "~> 1.0.0"},
      {:eqrcode, "~> 0.1.10"},

      # Hashing
      {:hashids, "~> 2.0"},

      # Assets
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},

      # Petal components
      {:petal_components, "~> 3.0"},

      # Utils
      {:blankable, "~> 1.0.0"},
      {:currency_formatter, "~> 0.4"},
      {:timex, "~> 3.7", override: true},
      {:tzdata, "~> 1.1.2"},
      {:inflex, "~> 2.1.0"},
      {:slugify, "~> 1.3"},
      {:sizeable, "~> 1.0"},

      # HTTP client
      {:tesla, "~> 1.8"},
      {:finch, "~> 0.14"},
      {:httpoison, "~> 2.0"},

      # Testing

      {:faker, "~> 0.17"},
      {:mimic, "~> 1.7", only: :test},
      {:exvcr, "~> 0.15", only: :test},

      # Jobs / Cron
      {:oban, "~> 2.19"},
      {:oban_web, "~> 2.11"},

      # Markdown
      {:earmark, "~> 1.4"},
      {:html_sanitize_ex, "~> 1.4"},

      # Security
      {:content_security_policy, "~> 1.0"},

      # Code quality
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.12", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test], runtime: false},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false},

      # Payments
      {:stripity_stripe, "~> 3.1"},

      # AI
      {:langchain, github: "brainlid/langchain"},

      # Temporary (to rename your project)
      {:rename_project, "~> 0.1.0", only: :dev, runtime: false},

      # MCP
      {:tidewave, "~> 0.1", only: :dev}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "cmd npm --prefix assets install"],
      "assets.build": ["tailwind default", "cmd npm --prefix assets run build"],
      "assets.deploy": [
        "cmd npm --prefix assets install",
        "cmd npm --prefix assets run deploy",
        "tailwind default --minify",
        "phx.digest"
      ],
      # Run to check the quality of your code
      quality: [
        "format",
        "sobelow --config",
        "coveralls",
        "credo"
      ],
      update_translations: ["gettext.extract --merge"],

      # Unlocks unused dependencies (no longer mentioned in the mix.exs file)
      clean_mix_lock: ["deps.unlock --unused"],
      seed: ["run priv/repo/seeds.exs"]
    ]
  end
end
