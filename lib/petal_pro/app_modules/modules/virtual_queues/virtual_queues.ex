defmodule PetalPro.AppModules.VirtualQueues do
  @moduledoc """
  Virtual Queues module for managing customer queues and tickets.

  Provides functionality for:
  - Creating and managing virtual queues
  - Customer ticket management
  - Real-time queue status updates
  - Kiosk and display board interfaces
  """

  @behaviour PetalPro.AppModules.Behaviours.AppModule

  # Internal contexts
  # alias PetalPro.AppModules.VirtualQueues.Analytics
  alias PetalPro.AppModules.VirtualQueues.Queues
  # alias PetalPro.AppModules.VirtualQueues.Tickets

  # Module behaviour implementations

  @impl true
  def code, do: "virtual_queues"

  @impl true
  def name, do: "Virtual Queues"

  @impl true
  def description do
    "Manage customer queues and provide real-time queue status updates"
  end

  @impl true
  def version, do: "1.0.0"

  @impl true
  def setup_org(_org_id, _opts \\ []) do
    # Initialize default queue settings for the org
    # with {:ok, _default_queue} <- create_default_queue(org_id) do
    #   :ok
    # end
    :ok
  end

  @impl true
  def cleanup_org(org_id) do
    # Archive or cleanup org data instead of deleting
    case Queues.archive_org_queues(org_id) do
      {:ok, _} -> :ok
      {:error, _} = error -> error
    end
  end

  @impl true
  def routes do
    %{
      main_route: "/virtual-queues",
      menu_items: [
        %{
          label: "Dashboard",
          path: "/virtual-queues",
          icon: "hero-home",
          description: "Overview of all queues"
        },
        %{
          label: "Manage Queues",
          path: "/virtual-queues",
          icon: "hero-queue-list",
          description: "Create and manage queues"
        }
        # %{
        #   label: "Analytics",
        #   path: "/virtual-queues/analytics",
        #   icon: "hero-chart-bar",
        #   description: "Queue performance analytics"
        # }
      ]
    }
  end

  @impl true
  def dashboard_widgets do
    [
      %{
        name: "active_queues",
        component: PetalProWeb.VirtualQueues.Components.ActiveQueuesWidget,
        title: "Active Queues",
        description: "Current queue status overview"
      },
      %{
        name: "queue_metrics",
        component: PetalProWeb.VirtualQueues.Components.QueueMetricsWidget,
        title: "Queue Metrics",
        description: "Today's queue performance"
      }
    ]
  end

  @impl true
  def sidebar_menu do
    [
      %{
        label: "Virtual Queues",
        icon: "hero-queue-list",
        path: "/virtual-queues",
        children: [
          %{label: "Dashboard", path: "/virtual-queues", icon: "hero-home"},
          %{label: "All Queues", path: "/virtual-queues", icon: "hero-queue-list"}
          # %{label: "Analytics", path: "/virtual-queues/analytics", icon: "hero-chart-bar"}
        ]
      }
    ]
  end

  # Public API - delegate to internal contexts

  # Queue management
  # defdelegate list_queues(opts \\ []), to: Queues
  # defdelegate get_queue!(id), to: Queues
  # defdelegate create_queue(attrs), to: Queues
  # defdelegate update_queue(queue, attrs), to: Queues
  # defdelegate delete_queue(queue), to: Queues
  # defdelegate get_queue_by_slug(slug), to: Queues
  # defdelegate call_next_ticket(queue), to: Queues

  # Ticket management
  # defdelegate list_tickets(opts \\ []), to: Tickets
  # defdelegate get_ticket!(id), to: Tickets
  # defdelegate create_ticket(attrs), to: Tickets
  # defdelegate update_ticket(ticket, attrs), to: Tickets
  # defdelegate join_queue(queue_id, customer_info \\ %{}), to: Tickets

  # Analytics
  # defdelegate get_queue_analytics(queue_id, date_range), to: Analytics
  # defdelegate get_org_analytics(org_id, date_range), to: Analytics

  # Private helper functions

  # defp create_default_queue(org_id) do
  #   default_attrs = %{
  #     name: "General Queue",
  #     description: "Default queue for general service",
  #     org_id: org_id,
  #     is_active: true,
  #     max_capacity: 100,
  #     # minutes
  #     estimated_service_time: 5,
  #     settings: %{
  #       auto_call_next: false,
  #       show_estimated_wait: true,
  #       allow_customer_info: true
  #     }
  #   }

  #   create_queue(default_attrs)
  # end
end
