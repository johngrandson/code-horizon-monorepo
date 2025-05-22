defmodule PetalPro.Events.Modules.Orgs.Broadcaster do
  @moduledoc false
  import Phoenix.PubSub

  alias PetalPro.Orgs

  require Logger

  @pubsub PetalPro.PubSub

  @doc """
  Broadcast invitation sent events to specific user-invitations combinations.
  """
  def broadcast_invitation_sent(invitation, org) do
    topic = "user:#{invitation.user_id}:invitations"

    payload = {
      :invitation_sent,
      %{
        invitation_id: invitation.id,
        org_id: org.id
      }
    }

    broadcast(@pubsub, topic, payload)
  end

  @doc """
  Broadcast invitation accepted events to specific user-org combinations.
  """
  def broadcast_invitation_accepted(invitation, org) do
    topic = "user:#{invitation.user_id}:invitations"

    payload = {
      :invitation_accepted,
      %{
        invitation_id: invitation.id,
        org_id: org.id
      }
    }

    broadcast(@pubsub, topic, payload)
  end

  @doc """
  Broadcast invitation rejected events to specific user-org combinations.
  """
  def broadcast_invitation_rejected(invitation, org) do
    topic = "org:#{org.id}:admin_notifications"

    payload = {
      :invitation_rejected,
      %{
        invitation_id: invitation.id,
        email: invitation.email,
        user_id: invitation.user_id,
        org_id: org.id
      }
    }

    Logger.info("Broadcasting invitation rejected: #{inspect(payload)}")
    broadcast(@pubsub, topic, payload)
  end

  @doc """
  Broadcast invitation deleted events to specific user-org combinations.
  """
  def broadcast_invitation_deleted(invitation) do
    topic = "user:#{invitation.user_id}:invitations"

    payload = {
      :invitation_deleted,
      %{
        invitation_id: invitation.id,
        org_id: invitation.org_id
      }
    }

    broadcast(@pubsub, topic, payload)
  end

  @doc """
  Broadcast invited to org events to specific user-org combinations.
  """
  def broadcast_invited_to_org(user, org) do
    topic = "user:#{user.id}:invitations"
    payload = {:invited_to_org, %{org_id: org.id}}

    broadcast(@pubsub, topic, payload)
  end

  @doc """
  Broadcast left org events to specific user-org combinations.
  """
  def broadcast_left_org(user, org) do
    topic = "user:#{user.id}:invitations"
    payload = {:left_org, %{org_id: org.id}}

    broadcast(@pubsub, topic, payload)
  end

  @doc """
  Broadcast to all members of an organization.
  """
  def broadcast_to_org_members(org, event, payload) do
    members = Orgs.list_members_by_org(org)

    for member <- members do
      topic = "user:#{member.user_id}:invitations"
      broadcast(@pubsub, topic, {event, payload})
    end
  end

  @doc """
  Broadcast to all admins of an organization.
  """
  def broadcast_to_org_admins(org, event, payload) do
    admin_members = Orgs.list_org_admin_users(org)

    for admin <- admin_members do
      topic = "user:#{admin.user_id}:invitations"
      broadcast(@pubsub, topic, {event, payload})
    end
  end
end
