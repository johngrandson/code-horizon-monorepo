# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# SETUP_TODO - ensure these details are correct
# Option descriptions:
#   - app_name: This appears in your email layout and also your meta title tag
#   - business_name: This appears in your landing page footer next to the copyright symbol
#   - support_email: In your transactional emails there is a "Contact us" email - this is what will appear there
#   - mailer_default_from_name: The "from" name for your transactional emails
#   - mailer_default_from_email: The "from" email for your transactional emails
#   - logo_url_for_emails: The URL to your logo for your transactional emails (needs to be a full URL, not a path)
#   - seo_description: Will go in your meta description tag
#   - twitter_url: (deletable) The URL to your Twitter account (used in the landing page footer)
#   - github_url: (deletable) The URL to your Github account (used in the landing page footer)
#   - discord_url: (deletable) The URL to your Discord invititation (used in the landing page footer)
config :petal_pro,
  app_name: "CodeHorizon",
  business_name: "CodeHorizon ",
  support_email: "support@example.com",
  mailer_default_from_name: "Support",
  mailer_default_from_email: "support@example.com",
  logo_url_for_emails: "https://shy-cloud-1717.t3.storage.dev/logo_for_emails.png",
  seo_description: "SaaS boilerplate template powered by Elixir's Phoenix and TailwindCSS",
  twitter_url: "https://twitter.com/PetalFramework",
  github_url: "https://github.com/petalframework",
  discord_url: "https://discord.gg/exbwVbjAct"

# Petal Pro features:
#   - impersonation_enabled?: Allows admins to impersonate users
#   - gdpr_mode: Enables GDPR mode which will not send personal data to OpenAI
config :petal_pro,
  impersonation_enabled?: true,
  gdpr_mode: true

config :petal_pro,
  ecto_repos: [PetalPro.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :petal_pro, PetalProWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PetalProWeb.ErrorHTML, json: PetalProWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PetalPro.PubSub,
  live_view: [signing_salt: "Fd8SWPu3"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :petal_pro, PetalPro.Mailer, adapter: Swoosh.Adapters.Local

# Timex
config :timex, :translator, PetalProWeb.Gettext

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :petal_components,
       :error_translator_function,
       {PetalProWeb.CoreComponents, :translate_error}

config :tailwind,
  version: "4.0.9",
  default: [
    args: ~w(
    --input=assets/css/app.css
    --output=priv/static/assets/app.css
  ),
    cd: Path.expand("..", __DIR__)
  ]

# Oban:
# Queues are specified as a keyword list where the key is the name of the queue and the value is the maximum number of concurrent jobs.
# The following configuration would start four queues with concurrency ranging from 5 to 50: [default: 10, mailers: 20, events: 50, media: 5]
# For now we just have one default queue with up to 5 concurrent jobs (as our database only accepts up to 10 connections so we don't want to overload it)
# Oban provides active pruning of completed, cancelled and discarded jobs - we retain jobs for 24 hours
config :petal_pro, Oban,
  repo: PetalPro.Repo,
  queues: [default: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 3600 * 24},
    {Oban.Plugins.Cron,
     crontab: [
       # {"@daily", PetalPro.Workers.ExampleWorker}
       # {"* * * * *", EveryMinuteWorker},
       # {"0 * * * *", EveryHourWorker},
       # {"0 */6 * * *", EverySixHoursWorker},
       # {"0 0 * * SUN", EverySundayWorker},
       # More examples: https://crontab.guru/examples.html
     ]}
  ]

# Specify which languages you support
# To create .po files for a language run `mix gettext.merge priv/gettext --locale fr`
# (fr is France, change to whatever language you want - make sure it's included in the locales config below)
config :petal_pro, PetalProWeb.Gettext, allowed_locales: ~w(en pt-BR)

config :petal_pro, :language_options, [
  %{locale: "pt-BR", flag: "🇧🇷", label: "Português"},
  %{locale: "en", flag: "🇬🇧", label: "English"}
]

# Social login providers
# Full list of strategies: https://github.com/ueberauth/ueberauth/wiki/List-of-Strategies
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]},
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email"]}
  ]

# SETUP_TODO - If you want to use Github auth, replace MyGithubUsername with your Github username
config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  headers: [
    "user-agent": "MyGithubUsername"
  ]

config :petal_pro, :passwordless_enabled, true

# Reduce XSS risks by declaring which dynamic resources are allowed to load
# If you use any CDNs, whitelist them here.
# Policy struct: https://github.com/mbramson/content_security_policy/blob/master/lib/content_security_policy/policy.ex
# Read more about the options: https://content-security-policy.com
# Note that we use unsafe-eval because Alpine JS requires it :( (see https://alpinejs.dev/advanced/csp)
config :petal_pro, :content_security_policy, %{
  default_src: [
    "'unsafe-inline'",
    "'unsafe-eval'",
    "'self'",
    "data:",
    "blob:",
    "https://cdnjs.cloudflare.com",
    "https://cdn.skypack.dev",
    "https://cdn.jsdelivr.net",
    "https://rsms.me",
    "https://res.cloudinary.com",
    "https://api.cloudinary.com",
    "https://lh3.googleusercontent.com",
    "https://validator.swagger.io",
    "*.amazonaws.com",
    "ws://localhost:#{String.to_integer(System.get_env("PORT") || "4000")}",

    # Editor.js
    "*.youtube.com",
    "play.google.com",
    "*.twitter.com"
  ]
}

config :flop, repo: PetalPro.Repo, default_limit: 20
config :tesla, :adapter, {Tesla.Adapter.Finch, name: PetalPro.Finch}

# :user or :org
config :petal_pro, :billing_entity, :org
config :petal_pro, :billing_provider, PetalPro.Billing.Providers.Stripe
config :petal_pro, :billing_provider_subscription_link, "https://dashboard.stripe.com/test/subscriptions/"

config :petal_pro, :billing_products, [
  %{
    id: "essential",
    name: "Essential",
    description: "Essential description",
    features: [
      "Essential feature 1",
      "Essential feature 2",
      "Essential feature 3"
    ],
    plans: [
      %{
        id: "essential-monthly",
        name: "Monthly",
        amount: 1900,
        interval: :month,
        allow_promotion_codes: true,
        trial_days: 7,
        items: [
          %{price: "price_1NLhPDIWVkWpNCp7trePDpmi", quantity: 1}
        ]
      },
      %{
        id: "essential-yearly",
        name: "Yearly",
        amount: 19_900,
        interval: :year,
        allow_promotion_codes: true,
        items: [
          %{price: "price_1NWBYjIWVkWpNCp7pw4GpjI6", quantity: 1}
        ]
      }
    ]
  },
  %{
    id: "business",
    name: "Business",
    description: "Business description",
    most_popular: true,
    features: [
      "Business feature 1",
      "Business feature 2",
      "Business feature 3"
    ],
    plans: [
      %{
        id: "business-monthly",
        name: "Monthly",
        amount: 4900,
        interval: :month,
        allow_promotion_codes: true,
        trial_days: 7,
        items: [
          %{price: "price_1NaFJNIWVkWpNCp77sx8X1HZ", quantity: 1}
        ]
      },
      %{
        id: "business-yearly",
        name: "Yearly",
        amount: 49_900,
        interval: :year,
        allow_promotion_codes: true,
        items: [
          %{price: "price_1NaFJNIWVkWpNCp79dJ3d12W", quantity: 1}
        ]
      }
    ]
  },
  %{
    id: "enterprise",
    name: "Enterprise",
    description: "Enterprise description",
    features: [
      "Enterprise feature 1",
      "Enterprise feature 2",
      "Enterprise feature 3"
    ],
    plans: [
      %{
        id: "enterprise-monthly",
        name: "Monthly",
        amount: 9900,
        interval: :month,
        allow_promotion_codes: true,
        items: [
          %{price: "price_1NaetcIWVkWpNCp7Ax802ZF1", quantity: 1}
        ]
      },
      %{
        id: "enterprise-yearly",
        name: "Yearly",
        amount: 99_900,
        interval: :year,
        allow_promotion_codes: true,
        items: [
          %{price: "price_1NaetuIWVkWpNCp7E2oJZ6I9", quantity: 1}
        ]
      }
    ]
  }
]

config :langchain,
  openai_key: "",
  openai_org_id: "",
  # optional
  openai_proj_id: ""

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
