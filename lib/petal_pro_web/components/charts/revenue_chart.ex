defmodule PetalProWeb.Components.Charts.RevenueChart do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Analytics
  alias PetalPro.Orgs.Org
  alias PetalPro.Repo

  @impl true
  def update(assigns, socket) do
    org_id = assigns.current_org.id

    socket =
      socket
      |> assign(assigns)
      |> assign_defaults()
      |> assign_new(:view_mode, fn -> "chart" end)
      |> load_revenue_data(org_id)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_metric", %{"value" => metric}, socket) do
    org_id = socket.assigns.current_org.id

    socket =
      socket
      |> assign(:selected_metric, metric)
      |> load_revenue_data(org_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("sync_data", _params, socket) do
    org_id = socket.assigns.current_org.id

    unless Repo.exists?(Org, id: org_id) do
      socket = put_flash(socket, :error, "Organization not found")

      {:noreply, socket}
    end

    # Trigger sync job
    %{org_id: org_id}
    |> PetalPro.Workers.MetricSyncWorker.new()
    |> Oban.insert()

    socket = put_flash(socket, :info, "Data sync started")

    {:noreply, socket}
  end

  defp assign_defaults(socket) do
    socket
    |> assign_new(:selected_metric, fn -> "revenue" end)
    |> assign_new(:start_date, fn -> Date.add(Date.utc_today(), -30) end)
    |> assign_new(:end_date, fn -> Date.utc_today() end)
  end

  defp load_revenue_data(socket, org_id) do
    filters = [
      org_id: org_id,
      metric_type: socket.assigns.selected_metric
      # period_range: {socket.assigns.start_date, socket.assigns.end_date}
    ]

    current_metric =
      Analytics.get_latest_metric(org_id, socket.assigns.selected_metric)

    chart_data =
      filters
      |> Analytics.list_metric_snapshots()
      |> Enum.sort_by(& &1.period_start)
      |> Enum.map(&serialize_metric_snapshot/1)

    socket
    |> assign(:current_metric, current_metric)
    |> assign(:chart_data, chart_data)
  end

  defp serialize_metric_snapshot(metric) do
    %{
      period_start: Date.to_string(metric.period_start),
      period_end: Date.to_string(metric.period_end),
      value: Decimal.to_string(metric.value),
      previous_value: Decimal.to_string(metric.previous_value || 0),
      change_percent: Decimal.to_string(metric.change_percent || 0),
      metric_type: metric.metric_type
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col bg-white shadow-2xs rounded-xl dark:bg-neutral-900">
      <div class="grid md:grid-cols-2 items-start gap-2 md:gap-4">
        <div class="space-y-1">
          <div class="relative inline-block">
            <select
              name="metric"
              phx-change="update_metric"
              phx-target={@myself}
              class="py-1.5 px-3.5 text-sm text-gray-800 rounded-lg border border-gray-200 hover:bg-gray-50 focus:outline-hidden focus:bg-gray-50 dark:bg-neutral-800 dark:border-neutral-700 dark:text-neutral-200 dark:hover:bg-neutral-700"
            >
              <option value="revenue" selected={@selected_metric == "revenue"}>Revenue</option>
              <option value="sales" selected={@selected_metric == "sales"}>Total Sales</option>
              <option value="subscriptions" selected={@selected_metric == "subscriptions"}>
                Subscriptions
              </option>
            </select>
          </div>

          <h4 class="text-2xl font-semibold text-gray-800 dark:text-neutral-200">
            <%= if @current_metric do %>
              ${format_currency(@current_metric.value)}
              <.trend_icon change={@current_metric.change_percent} />
            <% else %>
              $0.00
            <% end %>
          </h4>

          <%= if @current_metric do %>
            <p class={["text-sm", trend_color(@current_metric.change_percent)]}>
              {format_percentage(@current_metric.change_percent)}% vs previous period
            </p>
          <% end %>
        </div>

        <div class="flex md:justify-end items-center gap-x-1">
          <button class="py-1.5 sm:py-2 px-2.5 inline-flex items-center gap-x-1.5 text-sm sm:text-xs font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-2xs hover:bg-gray-50 focus:outline-hidden focus:bg-gray-50 dark:bg-neutral-800 dark:border-neutral-700 dark:text-neutral-300 dark:hover:bg-neutral-700">
            <svg class="shrink-0 size-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <rect width="18" height="18" x="3" y="4" rx="2" ry="2" />
              <line x1="16" x2="16" y1="2" y2="6" />
              <line x1="8" x2="8" y1="2" y2="6" />
              <line x1="3" x2="21" y1="10" y2="10" />
            </svg>
            {Date.to_string(@start_date)} - {Date.to_string(@end_date)}
          </button>
        </div>
      </div>

      <div class="flex justify-center sm:justify-end items-center gap-x-4 mt-5 sm:mt-0 sm:mb-6">
        <div class="inline-flex items-center">
          <span class="size-2.5 inline-block bg-blue-600 rounded-sm me-2"></span>
          <span class="text-[13px] text-gray-600 dark:text-neutral-400">Current Period</span>
        </div>
        <div class="inline-flex items-center">
          <span class="size-2.5 inline-block bg-purple-600 rounded-sm me-2"></span>
          <span class="text-[13px] text-gray-600 dark:text-neutral-400">Previous Period</span>
        </div>
      </div>

      <div class="min-h-[415px] flex items-center justify-center">
        <%= if Enum.empty?(@chart_data) do %>
          <div class="text-center">
            <p class="text-gray-500 dark:text-neutral-400 mb-2">No data available</p>
            <button
              phx-click="sync_data"
              phx-target={@myself}
              class="py-2 px-3 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 focus:outline-hidden focus:ring-2 focus:ring-blue-500"
            >
              {gettext("Sync Data")}
            </button>
          </div>
        <% else %>
          <!-- ✅ Área ideal para o chart -->
          <div class="w-full h-full">
            <canvas
              id={"revenue-chart-#{@myself}"}
              phx-hook="RevenueChartHook"
              data-chart-data={Jason.encode!(@chart_data)}
              data-metric-type={@selected_metric}
              class="h-[400px]"
            >
            </canvas>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp trend_icon(assigns) do
    ~H"""
    <%= if Decimal.positive?(@change) do %>
      <svg
        class="inline-block align-top mt-1 shrink-0 size-5 text-green-500"
        fill="currentColor"
        viewBox="0 0 24 24"
      >
        <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" />
        <polyline points="16 7 22 7 22 13" />
      </svg>
    <% else %>
      <svg
        class="inline-block align-top mt-1 shrink-0 size-5 text-red-500"
        fill="currentColor"
        viewBox="0 0 24 24"
      >
        <polyline points="22 17 13.5 8.5 8.5 13.5 2 7" />
        <polyline points="16 17 22 17 22 11" />
      </svg>
    <% end %>
    """
  end

  defp trend_color(change) do
    if Decimal.positive?(change), do: "text-green-500", else: "text-red-500"
  end

  defp format_currency(value) when is_binary(value), do: value

  defp format_currency(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
  end

  defp format_percentage(value) do
    value
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 1)
  end
end
