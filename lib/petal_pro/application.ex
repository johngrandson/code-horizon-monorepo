defmodule PetalPro.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias PetalPro.Settings

  @impl true
  def start(_type, _args) do
    children = [
      PetalProWeb.Telemetry,
      PetalPro.Repo,
      Settings.Initializer,
      PetalPro.QueueEventsTimer,
      {DNSCluster, query: Application.get_env(:petal_pro, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PetalPro.PubSub},
      PetalProWeb.Presence,
      {Task.Supervisor, name: PetalPro.BackgroundTask},
      # Start the Finch HTTP client for sending emails and Tesla
      {Finch, name: PetalPro.Finch},
      {Oban, Application.fetch_env!(:petal_pro, Oban)},
      # Start a worker by calling: PetalPro.Worker.start_link(arg)
      # {PetalPro.Worker, arg}
      # Start to serve requests, typically the last entry
      PetalProWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PetalPro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PetalProWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
