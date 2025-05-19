defmodule PetalProWeb.AdminUserLive.FormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Accounts

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Accounts.change_user_as_admin(user)

    roles =
      PetalPro.Accounts.User
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
     |> assign(:roles, roles)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_as_admin(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user_as_admin(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{model} successfully updated", model: gettext("User")))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    user_params = Map.put(user_params, "confirmed_at", DateTime.utc_now())

    case Accounts.create_user_as_admin(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{model} successfully created", model: gettext("User")))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
