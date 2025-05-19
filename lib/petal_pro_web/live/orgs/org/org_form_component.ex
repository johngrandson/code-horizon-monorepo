defmodule PetalProWeb.OrgFormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} phx-target={@myself} phx-submit="save" phx-change="validate">
        <.field field={@form[:name]} {alpine_autofocus()} phx-debounce="500" />
        <.field disabled field={@form[:slug]} />

        <div class="flex justify-end gap-2">
          <.button phx-disable-with={gettext("Saving...")}>{gettext("Save")}</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{org: org} = assigns, socket) do
    changeset = Orgs.change_org(org, %{})

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

  @impl true
  def handle_event("save", %{"org" => org_params}, socket) do
    save_org(socket, socket.assigns.action, org_params)
  end

  defp save_org(socket, :edit, org_params) do
    case Orgs.update_org(socket.assigns.org, org_params) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Organization updated successfully"))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_org(socket, :new, org_params) do
    case Orgs.create_org(socket.assigns.current_user, org_params) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Organization created successfully"))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
