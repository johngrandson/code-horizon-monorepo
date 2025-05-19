defmodule PetalProWeb.EditNotificationsLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.UserSettingsLayoutComponent

  alias PetalPro.Accounts
  alias PetalPro.Accounts.User

  def mount(_params, _session, socket) do
    {:ok, assign_form(socket, socket.assigns.current_user)}
  end

  def render(assigns) do
    ~H"""
    <.settings_layout current_page={:edit_notifications} current_user={@current_user}>
      <.form id="update_profile_form" for={@form} phx-change="update_profile">
        <.field
          type="checkbox"
          field={@form[:is_subscribed_to_marketing_notifications]}
          label={gettext("Allow marketing notifications")}
        />
      </.form>
    </.settings_layout>
    """
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    case Accounts.update_profile(socket.assigns.current_user, user_params) do
      {:ok, current_user} ->
        Accounts.user_lifecycle_action("after_update_profile", current_user)

        socket =
          socket
          |> put_flash(:info, gettext("Profile updated"))
          |> assign(current_user: current_user)
          |> assign_form(current_user)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Update failed. Please check the form for issues"))
          |> assign(form: to_form(changeset))

        {:noreply, socket}
    end
  end

  defp assign_form(socket, user) do
    assign(socket, form: to_form(User.profile_changeset(user)))
  end
end
