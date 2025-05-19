defmodule PetalPro.OrgsTest do
  use PetalPro.DataCase

  import PetalPro.AccountsFixtures
  import PetalPro.NotificationsFixtures
  import PetalPro.OrgsFixtures

  alias PetalPro.Notifications
  alias PetalPro.Notifications.UserNotification
  alias PetalPro.Orgs
  alias PetalPro.Orgs.Invitation
  alias PetalPro.PubSub

  defp org_invite_data(ctx) do
    org = org_fixture()
    org_admin = org_admin_fixture(org)

    new_user_email = unique_invitation_email()
    existing_user = user_fixture(%{confirmed_at: DateTime.utc_now()})
    notifications_topic = Notifications.user_notifications_topic(existing_user.id)
    Phoenix.PubSub.subscribe(PubSub, notifications_topic)

    Map.merge(ctx, %{
      org: org,
      org_admin: org_admin,
      existing_user: existing_user,
      new_user_email: new_user_email,
      notifications_topic: notifications_topic
    })
  end

  describe "send_org_invitation/3" do
    setup [:org_invite_data, :verify_on_exit!]

    test "new email - creates org invite and delivers via email", %{
      org: org,
      org_admin: current_user,
      new_user_email: email,
      notifications_topic: notifications_topic
    } do
      # email should be delivered
      Mimic.expect(PetalPro.Notifications.UserMailer, :deliver_org_invitation, fn _, _, _ ->
        {:ok, Swoosh.Email.new()}
      end)

      assert {:ok, txn_result} =
               Orgs.send_org_invitation(org, current_user, %{"email" => email})

      # no broadcast should be sent
      refute_receive %Phoenix.Socket.Broadcast{
        topic: ^notifications_topic,
        event: "notifications_updated"
      }

      assert %Invitation{} = txn_result.invitation
      assert txn_result |> Map.get(:user_notification) |> is_nil()
    end

    test "email already in db - creates org invite and user notification, delivers via email + web", %{
      org: org,
      org_admin: current_user,
      existing_user: existing_user,
      notifications_topic: notifications_topic
    } do
      # email should be delivered
      Mimic.expect(PetalPro.Notifications.UserMailer, :deliver_org_invitation, fn _, _, _ ->
        {:ok, Swoosh.Email.new()}
      end)

      assert {:ok, txn_result} = Orgs.send_org_invitation(org, current_user, %{"email" => existing_user.email})
      assert %Invitation{} = txn_result.invitation
      assert %UserNotification{id: notification_id, type: :invited_to_org} = Map.get(txn_result, :user_notification)

      # broadcast should be sent for update
      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^notifications_topic,
        event: "notifications_updated",
        payload: %{id: ^notification_id, type: :invited_to_org}
      }
    end
  end

  describe "rescind_and_delete_org_invitation/1" do
    setup :org_invite_data

    test "new email - deletes org invite", %{
      org: org,
      new_user_email: email,
      notifications_topic: notifications_topic
    } do
      %Invitation{} =
        invitation = invitation_fixture(org, %{email: email, user_id: nil})

      assert {:ok, _} = Orgs.rescind_and_delete_org_invitation(invitation)

      # no broadcast should be sent
      refute_receive %Phoenix.Socket.Broadcast{
        topic: ^notifications_topic,
        event: "notifications_updated"
      }

      # invitation should be deleted
      assert_raise Ecto.NoResultsError, fn ->
        Orgs.get_invitation_by_org!(org, invitation.id)
      end
    end

    test "email already in db - deletes org invite and associated user notification", %{
      org: org,
      existing_user: existing_user,
      notifications_topic: notifications_topic
    } do
      # setup previously sent invite + notification
      %Invitation{} = invitation = invitation_fixture(org, %{email: existing_user.email, user_id: existing_user.id})

      %UserNotification{} =
        notification_fixture(existing_user, %{type: :invited_to_org, recipient_id: existing_user.id, org_id: org.id})

      # rescind and delete
      assert {:ok, _} = Orgs.rescind_and_delete_org_invitation(invitation)

      # both invitation and notification should be deleted
      assert_raise Ecto.NoResultsError, fn ->
        Orgs.get_invitation_by_org!(org, invitation.id)
      end

      assert existing_user |> Notifications.list_user_notifications() |> Enum.empty?()

      # broadcast should be sent to remove stale notification
      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^notifications_topic,
        event: "notifications_updated"
      }
    end
  end
end
