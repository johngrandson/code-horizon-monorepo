defmodule PetalProWeb.UserNotificationsChannel do
  @moduledoc """
  A channel to intercept broadcasts to a user's notifications
  channel and forward them to the connect client(s).
  """
  use Phoenix.Channel

  def join("user_notifications:" <> authorized_user_id, _params, %{assigns: %{user_id: authorized_user_id}} = socket) do
    {:ok, socket}
  end

  def join("user_notifications:" <> _unauthorized_user_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  intercept ["notifications_updated"]

  def handle_out("notifications_updated", payload, socket) do
    push(socket, "notifications_updated", payload)
    {:noreply, socket}
  end
end
