defmodule PetalPro.Settings.Initializer do
  @moduledoc """
  Worker for initializing default settings.
  Ensures that the Repo is ready before trying to access the database.
  """

  use GenServer

  alias PetalPro.Settings

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    if init_settings?() do
      # Initialize settings asynchronously only if configured to do so
      Process.send_after(self(), :init_settings, 1000)
    end

    {:ok, %{initialized: false}}
  end

  @impl true
  def handle_info(:init_settings, state) do
    case Settings.init_default_settings() do
      :ok ->
        Logger.info("✅ Default settings initialized successfully")
        {:noreply, %{state | initialized: true}}

      :error ->
        Logger.error("❌ Failed to initialize default settings")
        # Retry after 5 seconds
        Process.send_after(self(), :init_settings, 5000)
        {:noreply, state}
    end
  end

  defp init_settings? do
    Application.get_env(:petal_pro, :init_settings, true)
  end
end
