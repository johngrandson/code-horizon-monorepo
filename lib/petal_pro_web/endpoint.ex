defmodule PetalProWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :petal_pro

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_petal_pro_key",
    signing_salt: "S+qhbMV3"
  ]

  if sandbox = Application.compile_env(:petal_pro, :sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox, sandbox: sandbox
  end

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [:user_agent, session: @session_options]]

  socket "/socket", PetalProWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :petal_pro,
    gzip: false,
    only: PetalProWeb.static_paths()

  # MCP server (development only)
  if Code.ensure_loaded?(Tidewave) do
    if Mix.env() == :dev do
      plug Tidewave
    end
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :petal_pro
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Stripe.WebhookPlug,
    at: "/webhooks/stripe",
    handler: PetalPro.Billing.Providers.Stripe.WebhookHandler,
    secret: {Application, :get_env, [:stripity_stripe, :signing_secret]}

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug PetalProWeb.Router
end
