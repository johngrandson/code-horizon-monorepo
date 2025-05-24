defmodule PetalProWeb.OrgTeamLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalPro.Events.Modules.Orgs.Subscriber
  import PetalProWeb.OrgSettingsLayoutComponent

  alias PetalPro.Orgs
  alias PetalPro.Orgs.Membership
  alias PetalPro.Repo

  on_mount {PetalProWeb.OrgOnMountHooks, :require_org_admin}

  @impl true
  def mount(_params, _session, socket) do
    is_org_admin = Membership.is_org_admin?(socket.assigns.current_user)

    socket =
      socket
      |> register_subscriber()
      |> assign(:is_org_admin, is_org_admin)
      |> assign_memberships()
      |> assign_invitations()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:invitation_sent, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket = assign_invitations(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:invitation_accepted, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket =
      socket
      |> assign_memberships()
      |> assign_invitations()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:invitation_rejected, %{org_id: org_id}}, socket) do
    socket =
      if socket.assigns.current_org.id == org_id do
        assign_invitations(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, gettext("Team"))
  end

  defp apply_action(socket, :invite, _params) do
    assign(socket, :page_title, gettext("Invite new member"))
  end

  defp apply_action(socket, :edit_membership, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit member"))
    |> assign(:membership, Orgs.get_membership!(id))
  end

  @impl true
  def handle_event("delete_member", %{"id" => id}, socket) do
    org = socket.assigns.current_org
    membership = Orgs.get_membership!(id)
    member_user = membership.user

    case Orgs.delete_membership(membership) do
      {:ok, membership} ->
        PetalPro.Logs.log("orgs.delete_member", %{
          user: socket.assigns.current_user,
          target_user: member_user,
          org_id: org.id
        })

        if membership.user_id == socket.assigns.current_user.id do
          {:noreply,
           socket
           |> put_flash(:info, gettext("You have left %{org_name}", org_name: org.name))
           |> push_navigate(to: PetalProWeb.Helpers.home_path(socket.assigns.current_user))}
        else
          PetalProWeb.UserAuth.disconnect_user_liveviews(member_user)

          {:noreply,
           socket
           |> put_flash(:info, gettext("Member deleted successfully"))
           |> assign_memberships()}
        end

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Something went wrong. Please try again or contact support if it keeps happening.")
         )}
    end
  end

  @impl true
  def handle_event("delete_invitation", %{"id" => id}, socket) do
    org = socket.assigns.current_org
    invitation = Orgs.get_invitation_by_org!(org, id)
    Orgs.rescind_and_delete_org_invitation(invitation)

    PetalPro.Logs.log("orgs.delete_invitation", %{
      user: socket.assigns.current_user,
      org_id: org.id,
      target_user_id: nil,
      metadata: %{
        email: invitation.email
      }
    })

    {:noreply,
     socket
     |> put_flash(:info, gettext("Invitation deleted successfully"))
     |> assign_invitations()}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/org/#{socket.assigns.current_org.slug}/team")}
  end

  def assign_memberships(socket) do
    memberships = Repo.preload(socket.assigns.current_org, memberships: :user).memberships
    assign(socket, memberships: memberships, members_count: length(memberships))
  end

  defp td_class(extra \\ ""), do: "dark:bg-gray-700/70 #{extra}"

  defp assign_invitations(socket) do
    invitations = Repo.preload(socket.assigns.current_org, invitations: :user).invitations
    assign(socket, :invitations, invitations)
  end
end
