defmodule PetalPro.Events.Modules.Notifications.Broadcaster do
  @moduledoc false

  alias PetalPro.Events.Modules.Notifications.UserNotification

  @doc """
  Returns the topic for a user's notifications.
  """
  def user_notifications_topic(user_id) when not is_nil(user_id), do: "user_notifications:#{user_id}"

  @doc """
  Broadcasts the `notifications_updated` event to the user's notifications topic.
  """
  def broadcast_user_notification(%UserNotification{
        id: notification_id,
        type: notification_type,
        recipient_id: recipient_id
      }) do
    PetalProWeb.Endpoint.broadcast(
      user_notifications_topic(recipient_id),
      "notifications_updated",
      %{id: notification_id, type: notification_type}
    )
  end

  def broadcast_user_notification(user_id) when not is_nil(user_id) do
    PetalProWeb.Endpoint.broadcast(
      user_notifications_topic(user_id),
      "notifications_updated",
      %{}
    )
  end
end
