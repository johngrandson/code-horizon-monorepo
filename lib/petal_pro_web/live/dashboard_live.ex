defmodule PetalProWeb.DashboardLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalPro.Events.Modules.Orgs.Subscriber

  alias PetalPro.Orgs
  alias PetalPro.Orgs.Membership

  @impl true
  def mount(_params, _session, socket) do
    orgs_with_roles = Membership.list_orgs_with_user_roles(socket.assigns.current_user)
    is_org_admin = Membership.is_org_admin?(socket.assigns.current_user)

    socket =
      socket
      |> assign(page_title: gettext("Dashboard"))
      |> assign(is_org_admin: is_org_admin)
      |> assign(orgs: orgs_with_roles)
      |> assign_invitations()
      |> register_subscriber()

    {:ok, socket}
  end

  @impl true
  def handle_info({:invitation_sent, _payload}, socket) do
    {:noreply, assign_invitations(socket)}
  end

  @impl true
  def handle_info({:invitation_deleted, _payload}, socket) do
    {:noreply, assign_invitations(socket)}
  end

  defp assign_invitations(socket) do
    assign(socket, :invitations, Orgs.list_invitations_by_user(socket.assigns.current_user))
  end
end
