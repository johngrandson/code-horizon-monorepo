defmodule PetalProWeb.VirtualQueues.QueueLive.Index do
  @moduledoc """
  LiveView for listing and managing Virtual Queues.
  Provides CRUD operations and queue overview functionality.
  """
  use PetalProWeb, :live_view

  alias PetalPro.AppModules.VirtualQueues.Queue
  alias PetalPro.AppModules.VirtualQueues.Queues

  @data_table_opts [
    default_limit: 25,
    default_order: %{order_by: [:name], order_directions: [:asc]},
    filterable: [:name, :status, :category],
    sortable: [:name, :status, :current_ticket_number, :last_served_ticket_number, :inserted_at]
  ]

  @impl true
  def mount(_params, _session, %{assigns: %{current_org: org}} = socket) do
    queues = Queues.list_queues([], org.id)

    socket =
      socket
      |> assign(:queues, queues)
      |> assign(:data_table_opts, @data_table_opts)
      |> assign(:selected_queue, nil)

    {:ok, socket}
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
    # Handle DataTable parameters for filtering and sorting
    filters = extract_filters(params)
    queues = Queues.list_queues(filters, socket.assigns.current_org.id)

    socket
    |> assign(:page_title, "Virtual Queues")
    |> assign(:selected_queue, nil)
    |> assign(:queues, queues)
  end

  @impl true
  def handle_info({VirtualQueuesWeb.QueueLive.FormComponent, {:saved, queue}}, socket) do
    updated_queues = Queues.list_queues([], socket.assigns.current_org.id)

    socket =
      socket
      |> put_flash(:info, "Queue #{queue.name} saved successfully")
      |> assign(:queues, updated_queues)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    queue = Queues.get_queue!(String.to_integer(id), socket.assigns.current_org.id)

    case Queues.delete_queue(queue) do
      {:ok, _} ->
        updated_queues = Queues.list_queues([], socket.assigns.current_org.id)

        socket =
          socket
          |> put_flash(:info, "Queue deleted successfully")
          |> assign(:queues, updated_queues)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete queue")}
    end
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
      {:ok, updated_queue} ->
        updated_queues = Queues.list_queues([], socket.assigns.current_org.id)

        socket =
          socket
          |> put_flash(:info, "Queue #{updated_queue.name} #{action}d successfully")
          |> assign(:queues, updated_queues)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update queue status")}
    end
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    filters = build_filters(filter_params)
    queues = Queues.list_queues(filters, socket.assigns.current_org.id)

    {:noreply, assign(socket, :queues, queues)}
  end

  # Helper functions

  defp extract_filters(params) do
    Enum.reduce(params, [], fn
      {"filter_" <> key, value}, acc when value != "" ->
        atom_key = String.to_atom(key)
        [{atom_key, value} | acc]

      _, acc ->
        acc
    end)
  end

  defp build_filters(filter_params) do
    Enum.reduce(filter_params, [], fn
      {key, value}, acc when value != "" and value != nil ->
        case key do
          "status" -> [{:status, String.to_atom(value)} | acc]
          "name" -> [{:name, value} | acc]
          _ -> acc
        end

      _, acc ->
        acc
    end)
  end

  defp queue_status_badge(status) do
    case status do
      :active -> {"Active", "success"}
      :inactive -> {"Inactive", "gray"}
      :paused -> {"Paused", "warning"}
      _ -> {"Unknown", "gray"}
    end
  end

  defp queue_stats_summary(queue) do
    stats = Queues.get_queue_stats(queue)

    %{
      waiting: stats.waiting,
      total: stats.total,
      operational: stats.operational
    }
  end

  defp can_manage_queue?(queue) do
    # Add permission logic here if needed
    Queue.operational?(queue)
  end

  defp format_last_activity(queue) do
    # Format the last activity timestamp
    if queue.updated_at do
      relative_time = Timex.from_now(queue.updated_at)
      "Updated #{relative_time}"
    else
      "No recent activity"
    end
  end
end
