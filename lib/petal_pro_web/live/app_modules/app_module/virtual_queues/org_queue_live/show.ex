defmodule PetalProWeb.VirtualQueues.OrgQueueLive.Show do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProComponents
  import PetalProWeb.AppModulesLayoutComponent
  import PetalProWeb.Cards

  alias PetalPro.AppModules.VirtualQueues.Queues

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"queue_id" => queue_id}, _, socket) do
    queue = Queues.get_queue!(String.to_integer(queue_id), socket.assigns.current_org.id)

    socket =
      socket
      |> assign(:page_title, queue.name)
      |> assign(:queue, queue)
      |> assign(:stats, get_queue_stats(queue))

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_status", %{"action" => action}, socket) do
    queue = socket.assigns.queue

    Logger.info("Toggle status: #{action}")

    result =
      case action do
        "pause" -> Queues.pause_queue(queue)
        "activate" -> Queues.activate_queue(queue)
        "deactivate" -> Queues.deactivate_queue(queue)
        _ -> {:error, :invalid_action}
      end

    case result do
      {:ok, updated_queue} ->
        socket =
          socket
          |> assign(:queue, updated_queue)
          |> assign(:stats, get_queue_stats(updated_queue))
          |> put_flash(:info, "Queue #{action}d successfully")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update queue status")}
    end
  end

  @impl true
  def handle_event("reset_counters", _, socket) do
    queue = socket.assigns.queue

    case Queues.reset_queue_counters(queue) do
      {:ok, updated_queue} ->
        socket =
          socket
          |> assign(:queue, updated_queue)
          |> assign(:stats, get_queue_stats(updated_queue))
          |> put_flash(:info, "Queue counters reset successfully")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not reset counters")}
    end
  end

  defp get_queue_stats(queue) do
    %{
      waiting_tickets: queue.current_ticket_number - queue.last_served_ticket_number,
      total_tickets: queue.current_ticket_number,
      served_tickets: queue.last_served_ticket_number
    }
  end

  defp status_color(status) do
    case status do
      :active -> "green"
      :paused -> "yellow"
      :inactive -> "gray"
      _ -> "gray"
    end
  end

  # Add these helper functions to your LiveView module

  defp action_color_class(color) do
    case color do
      "green" -> "text-green-500 dark:text-green-400"
      "red" -> "text-red-500 dark:text-red-400"
      "blue" -> "text-blue-500 dark:text-blue-400"
      "yellow" -> "text-yellow-500 dark:text-yellow-400"
      "gray" -> "text-gray-500 dark:text-gray-400"
      _ -> "text-gray-500 dark:text-gray-400"
    end
  end

  defp status_actions(queue) do
    case queue.status do
      :active ->
        [
          %{
            action: :pause,
            label: gettext("Pause Queue"),
            color: "yellow",
            icon: "hero-pause"
          },
          %{
            action: :deactivate,
            label: gettext("Deactivate Queue"),
            color: "red",
            icon: "hero-stop"
          }
        ]

      :paused ->
        [
          %{
            action: :activate,
            label: gettext("Activate Queue"),
            color: "green",
            icon: "hero-play"
          },
          %{
            action: :deactivate,
            label: gettext("Deactivate Queue"),
            color: "red",
            icon: "hero-stop"
          }
        ]

      :inactive ->
        [
          %{
            action: :activate,
            label: gettext("Activate Queue"),
            color: "green",
            icon: "hero-play"
          },
          %{
            action: :deactivate,
            label: gettext("Deactivate Queue"),
            color: "red",
            icon: "hero-stop"
          }
        ]

      _ ->
        []
    end
  end
end
