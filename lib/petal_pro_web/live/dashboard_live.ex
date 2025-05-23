defmodule PetalProWeb.DashboardLive do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.Orgs.Membership

  @impl true
  def mount(_params, _session, socket) do
    orgs_with_roles = Membership.list_orgs_with_user_roles(socket.assigns.current_user)

    socket =
      socket
      |> assign(page_title: gettext("Dashboard"))
      |> assign(orgs: orgs_with_roles)

    {:ok, socket}
  end
end
