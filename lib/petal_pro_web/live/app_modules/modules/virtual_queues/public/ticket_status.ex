defmodule PetalProWeb.VirtualQueues.DisplayQueueLive.TicketStatus do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.AppModules.VirtualQueues.Queries.Queues
  alias PetalPro.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Ticket Status #{assigns.ticket_number}</h1>
    </div>
    """
  end

  @impl true
  def mount(%{"queue_id" => queue_id, "org_slug" => org_slug, "ticket_number" => ticket_number}, _session, socket) do
    current_org = Orgs.get_org!(org_slug)
    queue = Queues.get_queue!(String.to_integer(queue_id), current_org.id)

    {:ok, assign(socket, queue: queue, ticket_number: ticket_number)}
  end
end
