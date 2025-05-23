defmodule PetalPro.Events.Modules.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.Events.Modules.Notifications` context.
  """
  alias PetalPro.Accounts
  alias PetalPro.Events.Modules.Notifications.UserNotification
  alias PetalPro.Notifications

  @valid_read_path "/some/path"
  @valid_notification_message "some notification message"

  def notification_fixture(user, attrs \\ %{}) do
    user
    |> valid_user_notification_attrs(attrs)
    |> Notifications.create_user_notification()
    |> case do
      {:ok, notification} -> notification
      {:error, changeset} -> raise "Failed to create notification: #{inspect(changeset)}"
    end
  end

  def valid_user_notification_attrs(%Accounts.User{id: recipient_id}, attrs) do
    Enum.into(attrs, %{
      read_path: attrs[:read_path] || @valid_read_path,
      type: attrs[:type] || Enum.random(UserNotification.types()),
      recipient_id: recipient_id,
      message: attrs[:message] || @valid_notification_message
    })
  end

  def valid_user_notification_attrs(attrs) do
    recipient_id = Map.get(attrs, :recipient_id)

    Enum.into(attrs, %{
      read_path: attrs[:read_path] || @valid_read_path,
      type: attrs[:type] || Enum.random(UserNotification.types()),
      recipient_id: recipient_id,
      message: attrs[:message] || @valid_notification_message
    })
  end
end
