defmodule PetalProWeb.AdminUserLive.MembershipComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Orgs

  @impl true
  def update(%{user: _user, membership: membership} = assigns, socket) do
    changeset = Orgs.change_membership(membership)

    roles =
      PetalPro.Orgs.Membership
      |> Ecto.Enum.values(:role)
      |> Enum.map(fn x ->
        {
          x |> Atom.to_string() |> Phoenix.Naming.humanize(),
          Atom.to_string(x)
        }
      end)
      |> Enum.reverse()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:orgs, Orgs.list_orgs())
     |> assign(:roles, roles)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"membership" => membership_params}, socket) do
    changeset =
      socket.assigns.membership
      |> Orgs.change_membership(membership_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"membership" => membership_params}, socket) do
    save_membership(socket, socket.assigns.action, membership_params)
  end

  defp save_membership(socket, :edit_membership, membership_params), do: save_membership(socket, :edit, membership_params)

  defp save_membership(socket, :edit, membership_params) do
    case Orgs.update_membership(socket.assigns.membership, membership_params) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{model} successfully updated", model: gettext("Membership")))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_membership(socket, :new_membership, membership_params), do: save_membership(socket, :new, membership_params)

  defp save_membership(socket, :new, %{"org_id" => org_id, "role" => role}) do
    org = Orgs.get_org_by_id!(org_id)

    case Orgs.create_membership(org, socket.assigns.user, String.to_existing_atom(role)) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{model} successfully created", model: gettext("Membership")))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
