defmodule PetalPro.NotificationsTest do
  use PetalPro.DataCase

  import PetalPro.AccountsFixtures
  import PetalPro.NotificationsFixtures

  alias PetalPro.Notifications
  alias PetalPro.Notifications.UserNotification
  alias PetalPro.PubSub

  defp user_and_other_user(ctx) do
    user = user_fixture()
    other_user = user_fixture()
    Map.merge(ctx, %{user: user, other_user: other_user})
  end

  describe "read_unread_user_notifications_for_path/2" do
    setup do
      user = user_fixture(%{confirmed_at: DateTime.utc_now()})
      notifications_topic = Notifications.user_notifications_topic(user.id)
      Phoenix.PubSub.subscribe(PubSub, notifications_topic)

      %{user: user, notifications_topic: notifications_topic}
    end

    test "marks user notifications with a :read_path matching the given request path as read", %{
      user: user,
      notifications_topic: notifications_topic
    } do
      request_path = "/requested/path"
      %UserNotification{id: should_read_notification_id} = notification_fixture(user, %{read_path: request_path})
      %UserNotification{id: stay_unread_notification_id} = notification_fixture(user, %{read_path: "/some/other/path"})

      assert {1, nil} = Notifications.read_unread_user_notifications_for_path(user, request_path)

      # broadcast should be sent
      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^notifications_topic,
        event: "notifications_updated"
      }

      refute should_read_notification_id |> Notifications.get_user_notification!() |> Map.get(:read_at) |> is_nil()
      assert stay_unread_notification_id |> Notifications.get_user_notification!() |> Map.get(:read_at) |> is_nil()
    end

    test "doesn't update notifications with a different :read_path to given request_path, doesn't broadcast update", %{
      user: user,
      notifications_topic: notifications_topic
    } do
      request_path = "/requested/path"
      %UserNotification{id: id_one} = notification_fixture(user, %{read_path: "/some/app/path"})
      %UserNotification{id: id_two} = notification_fixture(user, %{read_path: "/some/other/app/path"})

      assert {0, nil} = Notifications.read_unread_user_notifications_for_path(user, request_path)

      # broadcast should not be sent
      refute_receive %Phoenix.Socket.Broadcast{
        topic: ^notifications_topic,
        event: "notifications_updated"
      }

      assert id_one |> Notifications.get_user_notification!() |> Map.get(:read_at) |> is_nil()
      assert id_two |> Notifications.get_user_notification!() |> Map.get(:read_at) |> is_nil()
    end
  end

  describe "mark_all_user_notifications_as_read!/1" do
    setup :user_and_other_user

    test "marks all notifications for a user as read", %{user: user, other_user: other_user} do
      for _ <- 1..3, do: notification_fixture(user)
      for _ <- 1..3, do: notification_fixture(other_user)

      assert Notifications.count_unread_user_notifications(user) == 3
      Notifications.mark_all_user_notifications_as_read(user)
      assert Notifications.count_unread_user_notifications(user) == 0

      # other users notifivations should remain unchanged
      assert Notifications.count_unread_user_notifications(other_user) == 3
    end
  end

  describe "mark_user_notification_as_read!/1" do
    setup :user_and_other_user

    test "marks notification as read for authorized user", %{user: user} do
      notification = notification_fixture(user)

      assert is_nil(notification.read_at)
      assert {:ok, updated_notification} = Notifications.mark_user_notification_as_read(user, notification)
      refute is_nil(updated_notification.read_at)
    end

    test "returns unauthorized error if the user provided does not own the notification", %{
      user: user,
      other_user: other_user
    } do
      notification = notification_fixture(user)

      assert is_nil(notification.read_at)
      assert {:error, :unauthorized} = Notifications.mark_user_notification_as_read(other_user, notification)

      notification = Notifications.get_user_notification!(notification.id)
      assert is_nil(notification.read_at)
    end
  end

  describe "count_user_notifications/1" do
    setup :user_and_other_user

    test "returns the correct count of notifications for a user", %{user: user} do
      # Create notifications for the user
      no_of_notifications = Enum.random(1..5)
      for _ <- 1..no_of_notifications, do: notification_fixture(user)

      assert Notifications.count_user_notifications(user) == no_of_notifications
    end

    test "returns 0 - not nil - when no notifications exist for a user", %{user: user} do
      assert Notifications.count_user_notifications(user) == 0
    end
  end

  describe "count_unread_user_notifications/1" do
    setup :user_and_other_user

    test "returns the correct count of unread notifications for a user", %{user: user} do
      # create read notifications for the user
      no_of_read_notifications = Enum.random(1..5)
      for _ <- 1..no_of_read_notifications, do: notification_fixture(user, %{read_at: DateTime.utc_now()})

      # create unread notification
      notification_fixture(user)

      assert Notifications.count_unread_user_notifications(user) == 1
    end

    test "returns 0 unread when notifications exist for a user but they've all been read", %{user: user} do
      no_of_read_notifications = Enum.random(1..5)
      for _ <- 1..no_of_read_notifications, do: notification_fixture(user, %{read_at: DateTime.utc_now()})
      assert Notifications.count_unread_user_notifications(user) == 0
    end

    test "returns 0 - not nil - when no notifications exist for a user", %{user: user} do
      assert Notifications.count_unread_user_notifications(user) == 0
    end
  end

  describe "list_user_notifications/2" do
    setup :user_and_other_user

    test "lists all notifications for a user", %{user: user, other_user: other_user} do
      # these shouldn't be returned
      for _ <- 1..2, do: notification_fixture(other_user)

      # these should be returned
      for _ <- 1..3, do: notification_fixture(user)

      notifications = Notifications.list_user_notifications(user)

      assert length(notifications) == 3
      assert Enum.all?(notifications, fn notification -> notification.recipient_id == user.id end)
    end

    test "lists all unread notifications for a user with `:unread_only` opt", %{user: user} do
      notification_fixture(user, %{read_at: DateTime.utc_now()})
      notification_fixture(user, %{read_at: DateTime.utc_now()})
      %UserNotification{id: unread_notification_id} = notification_fixture(user)

      notifications = Notifications.list_user_notifications(user, unread_only: true)

      assert length(notifications) == 1
      [unread_notification] = notifications

      assert is_nil(unread_notification.read_at)
      assert unread_notification.id == unread_notification_id
    end

    test "lists all notifications up to given limit", %{user: user} do
      for _ <- 1..5, do: notification_fixture(user)
      notifications = Notifications.list_user_notifications(user, limit: 1)

      assert length(notifications) == 1
      [notification] = notifications

      assert notification.recipient_id == user.id
    end

    test "lists unread notifications up to given limit", %{user: user} do
      notification_fixture(user, %{read_at: DateTime.utc_now()})
      notification_fixture(user, %{read_at: DateTime.utc_now()})
      for _ <- 1..5, do: notification_fixture(user)

      notifications = Notifications.list_user_notifications(user, unread_only: true, limit: 1)

      assert length(notifications) == 1
      [notification] = notifications

      assert is_nil(notification.read_at)
      assert notification.recipient_id == user.id
    end
  end
end
