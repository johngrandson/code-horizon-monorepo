defmodule PetalPro.AppModules.VirtualQueues do
  @moduledoc """
  The public API for the Virtual Queues application module.
  It implements the `PetalPro.AppModules.Behaviours.AppModule` behaviour to integrate
  with the Petal Pro modular system.
  """
  @behaviour PetalPro.AppModules.Behaviours.AppModule

  alias Ecto.Changeset

  # Aliases for internal contexts
  alias PetalPro.AppModules.VirtualQueues.Queues
  alias PetalPro.AppModules.VirtualQueues.Tickets

  @impl true
  def code, do: "virtual_queues"

  @impl true
  def name, do: "Virtual Queues"

  @impl true
  def description, do: "A system for managing virtual waiting lines for various service locations."

  @impl true
  def version, do: "1.0.0"

  @impl true
  def setup_org(org_id) do
    # Create a default queue for the organization if one doesn't already exist.
    case Queues.create_queue(%{name: "Default Queue", description: "General service queue"}, org_id) do
      {:ok, _queue} ->
        :ok

      # If a queue with "Default Queue" name already exists (e.g., re-running setup),
      # we consider it a success.
      {:error,
       %Changeset{valid?: false, errors: [name: {"a queue with this name already exists for this organization", _}]}} ->
        :ok

      {:error, reason} ->
        handle_setup_error({:error, reason}, org_id)
    end
  end

  @impl true
  def cleanup_org(org_id) do
    # Clean up any resources when the module is removed from an org
    # This is a simplified example - you might want to add transaction handling
    # and more comprehensive cleanup
    with :ok <- Queues.delete_all_queues_for_org(org_id) do
      Tickets.delete_all_tickets_for_org(org_id)
    end
  end

  @impl true
  def routes do
    %{
      "virtual_queues" => [
        {PetalProWeb.VirtualQueues.QueueLive.Index, :index},
        {PetalProWeb.VirtualQueues.QueueLive.Show, :show},
        {PetalProWeb.VirtualQueues.TicketLive.Index, :index},
        {PetalProWeb.VirtualQueues.TicketLive.Show, :show}
      ]
    }
  end

  @doc """
  Optional: Returns dashboard widgets for this module.
  This is an optional callback from the AppModule behaviour.
  """
  @impl true
  def dashboard_widgets do
    [
      %{
        title: "Active Queues",
        component: {PetalProWeb.VirtualQueues.DashboardWidgets, :active_queues},
        size: :medium
      },
      %{
        title: "Recent Tickets",
        component: {PetalProWeb.VirtualQueues.DashboardWidgets, :recent_tickets},
        size: :large
      }
    ]
  end

  @doc """
  Optional: Returns sidebar menu items for this module.
  This is an optional callback from the AppModule behaviour.
  """
  @impl true
  def sidebar_menu do
    [
      %{
        label: "Queues",
        icon: "queue-list",
        route: "/virtual_queues/queues"
      },
      %{
        label: "Tickets",
        icon: "ticket",
        route: "/virtual_queues/tickets"
      }
    ]
  end

  # Private helper functions
  defp handle_setup_error({:error, reason}, org_id) do
    {:error, "Failed to create default queue for organization #{org_id}: #{inspect(reason)}"}
  end

  # Delegates all public API calls to the internal contexts.
  # This keeps the VirtualQueues module clean and acts as an entry point.

  # Queue functions
  defdelegate list_queues(filters, org_id), to: Queues
  defdelegate get_queue!(id, org_id), to: Queues
  defdelegate get_queue(id, org_id), to: Queues
  defdelegate create_queue(attrs, org_id), to: Queues
  defdelegate update_queue(queue, attrs), to: Queues
  defdelegate delete_queue(queue), to: Queues
  defdelegate add_ticket_to_queue(queue, attrs), to: Queues
  defdelegate call_next_ticket(queue), to: Queues

  # Ticket functions
  defdelegate list_tickets(filters, queue_id), to: Tickets
  defdelegate get_ticket!(id, queue_id), to: Tickets
  defdelegate get_ticket(id, queue_id), to: Tickets
  # create_ticket_with_number is not delegated as it's an internal function used by Queues context.
  defdelegate update_ticket(ticket, attrs), to: Tickets
  defdelegate delete_ticket(ticket), to: Tickets
  defdelegate call_ticket(ticket), to: Tickets
  defdelegate mark_serving(ticket), to: Tickets
  defdelegate mark_completed(ticket), to: Tickets
  defdelegate mark_missed(ticket), to: Tickets
  defdelegate mark_cancelled(ticket), to: Tickets
end
