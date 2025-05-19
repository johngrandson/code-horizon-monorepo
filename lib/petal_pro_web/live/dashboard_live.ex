defmodule PetalProWeb.DashboardLive do
  @moduledoc false
  use PetalProWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: gettext("Dashboard"))}
  end
end
