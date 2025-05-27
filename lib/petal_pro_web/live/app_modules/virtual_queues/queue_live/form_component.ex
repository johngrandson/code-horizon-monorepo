defmodule PetalProWeb.VirtualQueues.QueueLive.FormComponent do
  @moduledoc """
  Form component for creating and editing Virtual Queues.
  Handles validation and submission of queue data.
  """
  use PetalProWeb, :live_component

  alias PetalPro.AppModules.VirtualQueues.Queue
  alias PetalPro.AppModules.VirtualQueues.Queues

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="queue-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <!-- Basic Information -->
        <div class="space-y-4">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Basic Information
          </h3>

          <.input
            field={@form[:name]}
            type="text"
            label="Queue Name"
            placeholder="e.g., Customer Service, Technical Support"
            required
          />

          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            placeholder="Brief description of what this queue handles"
            rows="3"
          />
        </div>
        
    <!-- Configuration -->
        <div class="space-y-4 pt-6 border-t border-gray-200 dark:border-gray-600">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Configuration
          </h3>

          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <.input
              field={@form[:max_tickets_per_day]}
              type="number"
              label="Daily Ticket Limit"
              placeholder="100"
              min="1"
            />

            <div class="flex items-center pt-8">
              <.input field={@form[:daily_reset]} type="checkbox" label="Reset counters daily" />
            </div>
          </div>
        </div>
        
    <!-- Advanced Settings -->
        <div class="space-y-4 pt-6 border-t border-gray-200 dark:border-gray-600">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
              Advanced Settings
            </h3>
            <.button
              type="button"
              variant="ghost"
              size="sm"
              phx-click="toggle_advanced"
              phx-target={@myself}
            >
              <%= if @show_advanced do %>
                <.icon name="hero-x-mark" class="w-4 h-4 mr-1" /> Hide
              <% else %>
                <.icon name="hero-chevron-down" class="w-4 h-4 mr-1" /> Show
              <% end %>
            </.button>
          </div>

          <%= if @show_advanced do %>
            <div class="space-y-4 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <.input
                field={@form[:settings][:category]}
                type="select"
                label="Category"
                options={[
                  {"General", "general"},
                  {"Customer Service", "customer_service"},
                  {"Technical Support", "technical_support"},
                  {"Billing", "billing"},
                  {"Other", "other"}
                ]}
              />

              <.input
                field={@form[:settings][:priority_levels]}
                type="checkbox"
                label="Enable priority levels"
              />

              <.input
                field={@form[:settings][:customer_info_required]}
                type="checkbox"
                label="Require customer information"
              />

              <.input
                field={@form[:settings][:estimated_wait_time]}
                type="number"
                label="Estimated service time (minutes)"
                min="1"
              />
            </div>
          <% end %>
        </div>

        <:actions>
          <.button type="button" variant="outline" phx-click={JS.patch(@patch)}>
            Cancel
          </.button>
          <.button type="submit" phx-disable-with="Saving...">
            {if @action == :edit, do: "Update Queue", else: "Create Queue"}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{queue: queue} = assigns, socket) do
    changeset =
      case socket.assigns[:action] do
        :edit -> Queues.change_queue(queue)
        _ -> Queues.change_queue(%Queue{org_id: assigns.current_org.id})
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:show_advanced, false)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"queue" => queue_params}, socket) do
    # Merge settings into a nested map if they exist
    queue_params = normalize_queue_params(queue_params)

    changeset =
      socket.assigns.queue
      |> Queues.change_queue(queue_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"queue" => queue_params}, socket) do
    queue_params = normalize_queue_params(queue_params)
    save_queue(socket, socket.assigns.action, queue_params)
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket) do
    {:noreply, assign(socket, :show_advanced, !socket.assigns.show_advanced)}
  end

  defp save_queue(socket, :edit, queue_params) do
    case Queues.update_queue(socket.assigns.queue, queue_params) do
      {:ok, queue} ->
        notify_parent({:saved, queue})

        {:noreply,
         socket
         |> put_flash(:info, "Queue updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_queue(socket, :new, queue_params) do
    case Queues.create_queue(queue_params, socket.assigns.current_org.id) do
      {:ok, queue} ->
        notify_parent({:saved, queue})

        {:noreply,
         socket
         |> put_flash(:info, "Queue created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp normalize_queue_params(queue_params) do
    # Extract settings from form and nest them properly
    {settings, base_params} = Map.split(queue_params, ["settings"])

    settings_map =
      case settings["settings"] do
        nil -> %{}
        settings_params -> normalize_settings(settings_params)
      end

    Map.put(base_params, "settings", settings_map)
  end

  defp normalize_settings(settings_params) do
    Enum.reduce(settings_params, %{}, fn
      {key, value}, acc when value in ["true", "false"] ->
        Map.put(acc, key, value == "true")

      {key, value}, acc when is_binary(value) and value != "" ->
        case Integer.parse(value) do
          {int_value, ""} -> Map.put(acc, key, int_value)
          _ -> Map.put(acc, key, value)
        end

      {key, value}, acc when value != "" ->
        Map.put(acc, key, value)

      _, acc ->
        acc
    end)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
