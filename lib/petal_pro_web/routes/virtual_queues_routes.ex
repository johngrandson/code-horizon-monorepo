defmodule PetalProWeb.VirtualQueuesRoutes do
  @moduledoc """
  Routes for Virtual Queues module.
  Defines both admin/management routes and public display routes.
  """
  defmacro __using__(_) do
    quote do
      # Admin/Management routes - require authentication and module access
      scope "/app", PetalProWeb do
        pipe_through [:browser, :authenticated, :subscribed_entity]

        live_session :virtual_queues_authenticated,
          on_mount: [
            {PetalProWeb.UserOnMountHooks, :require_authenticated_user},
            {PetalProWeb.OrgOnMountHooks, :assign_org_data},
            {PetalProWeb.SubscriptionPlugs, :subscribed_entity},
            {PetalProWeb.AppModuleOnMountHooks, {:require_module, "virtual_queues"}}
          ] do
          # # Queue management routes

          # # Queue management actions
          # live "/virtual-queues/:id/manage", VirtualQueues.OrgQueueLive.Manage, :manage
          # live "/virtual-queues/:id/analytics", VirtualQueues.OrgQueueLive.Analytics, :analytics
          # live "/virtual-queues/:id/settings", VirtualQueues.OrgQueueLive.Settings, :settings

          # # Ticket management within queues
          # live "/virtual-queues/:queue_id/tickets", VirtualQueues.TicketLive.Index, :index
          # live "/virtual-queues/:queue_id/tickets/new", VirtualQueues.TicketLive.Index, :new
          # live "/virtual-queues/:queue_id/tickets/:id", VirtualQueues.TicketLive.Show, :show
          # live "/virtual-queues/:queue_id/tickets/:id/edit", VirtualQueues.TicketLive.Show, :edit
        end

        # Organization-scoped routes
        scope "/org/:org_slug" do
          live_session :virtual_queues_org_authenticated,
            on_mount: [
              {PetalProWeb.UserOnMountHooks, :require_authenticated_user},
              {PetalProWeb.OrgOnMountHooks, :assign_org_data},
              {PetalProWeb.SubscriptionPlugs, :subscribed_org},
              {PetalProWeb.AppModuleOnMountHooks, {:require_module, "virtual_queues"}}
            ] do
            # Organization-specific queue management
            live "/virtual-queues", VirtualQueues.OrgQueueLive.Index, :index
            live "/virtual-queues/new", VirtualQueues.OrgQueueLive.Index, :new
            live "/virtual-queues/:queue_id/edit", VirtualQueues.OrgQueueLive.Index, :edit
            live "/virtual-queues/:queue_id", VirtualQueues.OrgQueueLive.Show, :show
            live "/virtual-queues/:queue_id/show/edit", VirtualQueues.OrgQueueLive.Show, :edit
            live "/virtual-queues/:queue_id/manage", VirtualQueues.OrgQueueLive.Manage, :manage
          end
        end
      end

      # Public display routes - no authentication required
      scope "/", PetalProWeb do
        pipe_through [:browser, :public_layout]

        live_session :virtual_queues_assigns_org_data,
          on_mount: [
            {PetalProWeb.OrgOnMountHooks, :assign_public_org_data}
          ] do
          # Public queue display - customers can view queue status
          live "/queue/:org_slug/", VirtualQueues.DisplayQueueLive.ListQueues, :list
          live "/queue/:org_slug/:queue_id/join", VirtualQueues.DisplayQueueLive.JoinQueue, :join
          live "/queue/:org_slug/:queue_id/watch", VirtualQueues.DisplayQueueLive.WatchQueue, :watch
          live "/queue/:org_slug/:queue_id", VirtualQueues.DisplayQueueLive.PublicQueue, :show
          live "/queue/:org_slug/:queue_id/status/:ticket_number", VirtualQueues.DisplayQueueLive.TicketStatus, :status

          # Kiosk mode - for touch screens in physical locations
          # live "/kiosk/:queue_id", VirtualQueues.DisplayQueueLive.Kiosk, :kiosk
          # live "/kiosk/:queue_id/success", VirtualQueues.DisplayQueueLive.Kiosk, :success

          # Display board - shows current queue status on large screens
          # live "/display/:queue_id", VirtualQueues.DisplayQueueLive.Board, :board
        end
      end

      # # API routes for mobile apps and integrations
      # scope "/api/virtual-queues", PetalProWeb.Api.VirtualQueues, as: :api_virtual_queues do
      #   pipe_through [:api, :api_authenticated]

      #   resources "/queues", QueueController, only: [:index, :show] do
      #     resources "/tickets", TicketController, only: [:index, :create, :show, :update]
      #   end

      #   # Special API endpoints
      #   post "/queues/:id/join", QueueController, :join_queue
      #   post "/queues/:id/call-next", QueueController, :call_next_ticket
      #   get "/tickets/:id/status", TicketController, :get_status
      # end
    end
  end
end
