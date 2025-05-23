defmodule PetalPro.Events.Modules.Notifications.UserNotificationAttrs do
  @moduledoc """
  A module to house user notification attribute definitions for use in the Notifications context.
  """
  use PetalProWeb, :verified_routes
  use Gettext, backend: PetalProWeb.Gettext

  alias PetalPro.Orgs.Org

  @doc """
  Returns the attrs required for a user notification sent when a user is invited to an org.
  """
  def invite_to_org_notification(%Org{} = org, sender_id, recipient_id) do
    %{
      read_path: ~p"/app/users/org-invitations",
      type: :invited_to_org,
      recipient_id: recipient_id,
      sender_id: sender_id,
      org_id: org.id,
      message: gettext("You have been invited to join the %{org_name} organization!", org_name: org.name)
    }
  end
end
