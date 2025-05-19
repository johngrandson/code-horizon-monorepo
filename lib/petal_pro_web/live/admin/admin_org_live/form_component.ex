defmodule PetalProWeb.AdminOrgLive.FormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Orgs

  @impl true
  def update(%{org: org} = assigns, socket) do
    changeset = Orgs.change_org(org)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    changeset =
      socket.assigns.org
      |> Orgs.change_org(org_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"org" => org_params}, socket) do
    save_org(socket, socket.assigns.action, org_params)
  end

  defp save_org(socket, :edit, org_params) do
    case Orgs.update_org(socket.assigns.org, org_params) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{model} successfully updated", model: gettext("Organization")))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_org(socket, :new, org_params) do
    case Orgs.create_org(org_params) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{model} successfully created", model: gettext("Organization")))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
