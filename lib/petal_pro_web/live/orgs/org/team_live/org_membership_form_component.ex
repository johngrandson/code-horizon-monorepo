defmodule PetalProWeb.OrgTeamLive.OrgMembershipFormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="form-membership"
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <.field type="radio-group" field={@form[:role]} label={gettext("Role")} options={@roles} />

        <%= if @membership.user_id == @current_membership.user_id && @membership.role == :admin do %>
          <.alert color="warning" class="my-5" heading={gettext("Be careful")}>
            {gettext("By removing yourself from admin you won't be able to regain access.")}
          </.alert>
        <% end %>

        <div class="flex justify-end">
          <.button phx-disable-with={gettext("Saving...")}>{gettext("Save")}</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Orgs.change_membership(assigns.membership)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:roles, Enum.map(Orgs.membership_roles(), &{String.capitalize(&1), &1}))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"membership" => params}, socket) do
    changeset =
      socket.assigns.membership
      |> Orgs.change_membership(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"membership" => params}, %{assigns: %{membership: membership}} = socket) do
    case Orgs.update_membership(membership, params) do
      {:ok, membership} ->
        PetalPro.Logs.log("orgs.update_member", %{
          user: socket.assigns.current_user,
          target_user_id: membership.user_id,
          org_id: membership.org_id,
          metadata: %{
            role: membership.role
          }
        })

        {:noreply,
         socket
         |> put_flash(:info, gettext("Membership updated successfully"))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
