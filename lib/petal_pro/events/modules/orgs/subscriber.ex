defmodule PetalPro.Events.Modules.Orgs.Subscriber do
  @moduledoc false

  import Phoenix.LiveView

  alias PetalPro.Orgs.Membership

  require Logger

  def register_subscriber(socket) do
    if connected?(socket) do
      user_id = socket.assigns.current_user.id

      # Always subscribe to general invitations
      invitation_topic = "user:#{user_id}:invitations"
      Phoenix.PubSub.subscribe(PetalPro.PubSub, invitation_topic)

      Logger.info("[SUBSCRIPTION] - User #{user_id} is subscribed to invitation topic: #{invitation_topic}")

      if socket.assigns[:current_membership] && socket.assigns.current_membership.role == :admin do
        org_id = socket.assigns.current_org.id

        admin_topic = "org:#{org_id}:admin_notifications"
        Phoenix.PubSub.subscribe(PetalPro.PubSub, admin_topic)
      end

      # If user has orgs, subscribe to org-specific events
      case Membership.list_orgs_by_user(socket.assigns.current_user) do
        [] ->
          Logger.info("[SUBSCRIPTION] - User #{user_id} has no orgs, subscribed only to invitations")

        orgs when is_list(orgs) ->
          for org <- orgs do
            org_topic = "user:#{user_id}:org:#{org.id}"
            Phoenix.PubSub.subscribe(PetalPro.PubSub, org_topic)
          end

          Logger.info("[SUBSCRIPTION] - User #{user_id} is subscribed to #{length(orgs)} org topics")
      end
    end

    socket
  end
end
