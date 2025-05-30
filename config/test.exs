import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :petal_pro, PetalPro.Repo,
  username: "postgres",
  password: "postgres",
  database: "petal_pro_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :petal_pro, PetalProWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cPNzM6yNbuYM9FcYYtqL/PPFpiGQD5Tdxe4pRe8KYGFJ8gwI3Zgl6VL80H6pFeOp",
  server: true

config :petal_pro,
  impersonation_enabled?: true,
  gdpr_mode: false

# In test we don't send emails.
config :petal_pro, PetalPro.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :email_checker, validations: [EmailChecker.Check.Format]
config :petal_pro, :env, :test

config :petal_pro, PetalProWeb.Gettext,
  allowed_locales: ~w(en pt-BR),
  default_locale: "en"

config :petal_pro, :sandbox, Ecto.Adapters.SQL.Sandbox

# Disable default settings initialization in tests
config :petal_pro, :init_settings, false

# Oban - Disable plugins, enqueueing scheduled jobs and job dispatching altogether when testing
config :petal_pro, Oban, testing: :manual

config :exvcr,
  global_mock: true,
  vcr_cassette_library_dir: "test/support/fixtures/vcr_cassettes",
  filter_request_headers: ["Authorization"]

# Disable automatic timezone data updates during testing
config :tzdata, :autoupdate, :disabled

config :petal_pro, :billing_entity, :org

config :petal_pro, :billing_provider, PetalPro.Billing.Providers.Stripe

config :petal_pro, :billing_products, [
  %{
    id: "prod1",
    name: "Prod 1",
    description: "Prod 1 description",
    features: [
      "Prod 1 feature 1",
      "Prod 1 feature 2",
      "Prod 1 feature 3"
    ],
    plans: [
      %{
        id: "plan1-1",
        name: "Plan 1",
        amount: 100,
        interval: :month,
        allow_promotion_codes: true,
        items: [
          %{price: "item1-1-1", quantity: 1}
        ]
      }
    ]
  },
  %{
    id: "prod2",
    name: "Prod 2",
    description: "Prod 2 description",
    features: [
      "Prod 1 feature 1",
      "Prod 1 feature 2"
    ],
    plans: [
      %{
        id: "plan2-1",
        name: "Plan 2-1",
        amount: 200,
        interval: :month,
        allow_promotion_codes: true,
        items: [
          %{price: "item2-1-1", quantity: 1},
          %{price: "item2-1-2", quantity: 1}
        ]
      },
      %{
        id: "plan2-2",
        name: "Plan 2-2",
        amount: 2_000,
        interval: :year,
        allow_promotion_codes: true,
        items: [
          %{price: "item2-1-1", quantity: 1},
          %{price: "item2-2-1", quantity: 1}
        ]
      }
    ]
  },
  %{
    # this is a "real" product in Petal Pro's Stripe test account,
    # used for testing against the Stripe API, in conjunction with ExVCR
    id: "stripe-test-plan-a",
    name: "Petal Pro Test Plan A",
    description: "Petal Pro Test Plan A",
    features: [],
    plans: [
      %{
        id: "stripe-test-plan-a-monthly",
        name: "Monthly",
        amount: 199,
        interval: :month,
        allow_promotion_codes: true,
        trial_days: 7,
        items: [
          %{price: "price_1OQj8TIWVkWpNCp7ZlUSOaI9", quantity: 1}
        ]
      },
      %{
        id: "stripe-test-plan-a-yearly",
        name: "Yearly",
        amount: 1900,
        interval: :month,
        allow_promotion_codes: true,
        items: [
          %{price: "price_1OQj8pIWVkWpNCp74VstFtnd", quantity: 1}
        ]
      }
    ]
  }
]
