defmodule PetalProWeb.VirtualQueues.QueueLive.Index do
  @moduledoc """
  LiveView for listing and managing Virtual Queues.
  Provides CRUD operations and queue overview functionality.
  """
  use PetalProWeb, :live_view

  import PetalProWeb.AppModulesLayoutComponent
  import PetalProWeb.DataTable.Actions

  alias PetalPro.AppModules.VirtualQueues.Queue
  alias PetalPro.AppModules.VirtualQueues.Queues

  require Logger

  @data_table_opts [
    default_limit: 10,
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    },
    filterable: [
      :name,
      :status,
      :category
    ],
    sortable: [
      :name,
      :status,
      :current_ticket_number,
      :last_served_ticket_number,
      :inserted_at
    ]
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, index_params: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    queue = Queues.get_queue!(String.to_integer(id), socket.assigns.current_org.id)

    socket
    |> assign(:page_title, "Edit Queue")
    |> assign(:selected_queue, queue)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Queue")
    |> assign(:selected_queue, %Queue{org_id: socket.assigns.current_org.id})
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing Queues")
    |> assign_queues(params)
    |> assign(index_params: params)
  end

  defp current_index_path(socket, index_params) do
    ~p"/app/org/#{socket.assigns.current_org.slug}/virtual-queues?#{index_params || %{}}"
  end

  @impl true
  def handle_event("toggle_status", %{"id" => id, "action" => action}, socket) do
    queue = Queues.get_queue!(String.to_integer(id), socket.assigns.current_org.id)

    result =
      case action do
        "pause" -> Queues.pause_queue(queue)
        "activate" -> Queues.activate_queue(queue)
        "deactivate" -> Queues.deactivate_queue(queue)
        _ -> {:error, :invalid_action}
      end

    case result do
      {:ok, _updated_queue} ->
        socket =
          socket
          |> put_flash(:info, gettext("Queue status updated successfully"))
          |> assign_queues(socket.assigns.index_params || %{})

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not update queue status"))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    queue = Queues.get_queue!(String.to_integer(id), socket.assigns.current_org.id)

    case Queues.delete_queue(queue) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, gettext("Queue deleted successfully"))
          |> assign_queues(socket.assigns.index_params || %{})

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not delete queue"))}
    end
  end

  @impl true
  def handle_event("update_filters", params, socket) do
    query_params = PetalProWeb.DataTable.build_filter_params(socket.assigns.meta.flop, params)
    {:noreply, push_patch(socket, to: ~p"/app/org/#{socket.assigns.current_org.slug}/virtual-queues?#{query_params}")}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: current_index_path(socket, socket.assigns.index_params))}
  end

  defp assign_queues(socket, params) do
    starting_query =
      Queue
      |> Queue.by_org(socket.assigns.current_org.id)
      |> Queue.not_deleted()

    {queues, meta} = PetalProWeb.DataTable.search(starting_query, params, @data_table_opts)
    assign(socket, queues: queues, meta: meta)
  end

  defp queue_actions(queue, current_membership, current_org) do
    base_actions = [
      %{type: :view, route: ~p"/app/org/#{current_org.slug}/virtual-queues/#{queue}"},
      %{type: :edit, route: ~p"/app/org/#{current_org.slug}/virtual-queues/#{queue}/edit"}
    ]

    status_actions = queue_status_actions(queue)
    delete_actions = queue_delete_actions(queue, current_membership)

    base_actions ++ status_actions ++ delete_actions
  end

  defp queue_status_actions(queue) do
    case queue.status do
      :active ->
        [
          %{type: :divider},
          %{
            type: :custom,
            label: gettext("Pause Queue"),
            icon: "hero-pause",
            event: "toggle_status",
            phx_value: %{action: "pause"},
            class: "text-yellow-600 hover:bg-yellow-50"
          },
          %{
            type: :custom,
            label: gettext("Deactivate Queue"),
            icon: "hero-stop",
            event: "toggle_status",
            phx_value: %{action: "deactivate"},
            class: "text-orange-600 hover:bg-orange-50"
          }
        ]

      :paused ->
        [
          %{type: :divider},
          %{
            type: :custom,
            label: gettext("Resume Queue"),
            icon: "hero-play",
            event: "toggle_status",
            phx_value: %{action: "activate"},
            class: "text-green-600 hover:bg-green-50"
          }
        ]

      :inactive ->
        [
          %{type: :divider},
          %{
            type: :custom,
            label: gettext("Activate Queue"),
            icon: "hero-play",
            event: "toggle_status",
            phx_value: %{action: "activate"},
            class: "text-green-600 hover:bg-green-50"
          }
        ]
    end
  end

  defp queue_delete_actions(queue, current_membership) do
    if can_delete_queue?(current_membership, queue) do
      [
        %{type: :divider},
        %{
          type: :delete,
          confirm: "Are you sure you want to delete '#{queue.name}'? This cannot be undone."
        }
      ]
    else
      []
    end
  end

  # Permission helper (adjust based on your authorization system)
  defp can_delete_queue?(membership, queue) do
    membership.role in [:admin] and queue.status == :inactive
  end

  # Add helper function for status badge
  defp queue_status_badge(assigns) do
    {text, color} =
      case assigns.status do
        :active -> {gettext("Active"), "success"}
        :inactive -> {gettext("Inactive"), "gray"}
        :paused -> {gettext("Paused"), "warning"}
        _ -> {gettext("Unknown"), "gray"}
      end

    assigns = assigns |> assign(:text, text) |> assign(:color, color)

    ~H"""
    <.badge color={@color}>{@text}</.badge>
    """
  end
end
