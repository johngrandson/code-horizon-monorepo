defmodule PetalProWeb.VirtualQueues.DisplayQueueLive.PublicQueue do
  @moduledoc """
  LiveView implementation for the enhanced Queue Dashboard.
  Handles real-time updates, notifications, and user interactions.
  """
  use PetalProWeb, :live_view

  import PetalProWeb.Components.QueueDashboard

  alias PetalPro.AppModules.VirtualQueues.QueueEventsScheduler

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    org_id = socket.assigns.current_org.id

    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)

      case QueueEventsScheduler.subscribe(org_id) do
        :ok -> :ok
        error -> Logger.warning("Failed to subscribe to queue events: #{inspect(error)}")
      end
    end

    socket =
      socket
      |> assign(:org_id, org_id)
      |> assign_timer_states()
      |> assign_queue_data()
      |> assign_ui_data()

    {:ok, socket}
  end

  # ✅ Add cleanup when LiveView terminates
  @impl true
  def terminate(_reason, socket) do
    if socket.assigns[:org_id] do
      QueueEventsScheduler.unsubscribe(socket.assigns.org_id)
    end

    :ok
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, :current_time, DateTime.now!("America/Sao_Paulo"))}
  end

  @impl true
  def handle_info({:footer_news_state, _show_footer_news, org_id}, socket) do
    if org_id == socket.assigns.org_id do
      socket = assign_timer_states(socket)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:merchandise_state, _show_merchandise, org_id}, socket) do
    if org_id == socket.assigns.org_id do
      socket = assign_timer_states(socket)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_theme", _params, socket) do
    {:noreply, assign(socket, :is_dark, !socket.assigns.is_dark)}
  end

  @impl true
  def handle_event("call_next", _params, socket) do
    next_ticket = List.first(socket.assigns.queue_items)

    if next_ticket do
      new_current = %{
        number: next_ticket.ticket,
        counter: 3,
        service:
          case next_ticket.status do
            :priority -> "Atendimento Prioritário"
            :business -> "Atendimento Empresarial"
            _ -> "Atendimento Geral"
          end
      }

      remaining_queue = Enum.drop(socket.assigns.queue_items, 1)

      socket =
        socket
        |> assign(:current_ticket, new_current)
        |> assign(:queue_items, remaining_queue)
        |> assign(:stats, Map.put(socket.assigns.stats, :people_in_queue, length(remaining_queue)))

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # ✅ Extract timer states with error handling
  defp assign_timer_states(socket) do
    %{
      show_merchandise: show_merchandise,
      show_footer_news: show_footer_news
    } = QueueEventsScheduler.get_state()

    socket
    |> assign(:show_merchandise, show_merchandise)
    |> assign(:show_footer_news, show_footer_news)
  rescue
    error ->
      Logger.warning("❌ Failed to get timer state: #{inspect(error)}")

      socket
      |> assign(:show_merchandise, false)
      |> assign(:show_footer_news, false)
  end

  # Assign queue-related data
  defp assign_queue_data(socket) do
    socket
    |> assign(:current_ticket, %{
      number: "A047",
      counter: 3,
      service: "Atendimento Geral"
    })
    |> assign(:queue_items, [
      %{ticket: "A048", status: :waiting},
      %{ticket: "A049", status: :waiting},
      %{ticket: "B012", status: :priority}
    ])
    |> assign(:counters, build_counters())
    |> assign(:stats, %{
      people_in_queue: 24,
      average_time: "8min",
      served_today: 142,
      active_counters: "6/8"
    })
  end

  # Assign UI-related data
  defp assign_ui_data(socket) do
    socket
    |> assign(:current_time, DateTime.now!("America/Sao_Paulo"))
    |> assign(:is_dark, true)
    |> assign(:news_items, build_news_items())
  end

  defp build_counters do
    [
      %{id: 1, status: :active, current_ticket: "A047", service: "Atendimento Geral"},
      %{id: 2, status: :active, current_ticket: "B011", service: "Atendimento Prioritário"},
      %{id: 3, status: :active, current_ticket: "C004", service: "Atendimento Empresarial"},
      %{id: 4, status: :break, current_ticket: nil, service: nil},
      %{id: 5, status: :active, current_ticket: "A046", service: "Atendimento Geral"},
      %{id: 6, status: :active, current_ticket: "B010", service: "Atendimento Prioritário"},
      %{id: 7, status: :offline, current_ticket: nil, service: nil},
      %{id: 8, status: :offline, current_ticket: nil, service: nil}
    ]
  end

  defp build_news_items do
    [
      "🔔 Lembrete: O atendimento será encerrado às 17h hoje",
      "📋 Novos documentos necessários para abertura de conta corrente disponíveis no site",
      "⏰ Horário especial de funcionamento no feriado: 8h às 12h",
      "💳 Cartões com chip serão entregues em até 5 dias úteis",
      "📱 Baixe nosso aplicativo e evite filas desnecessárias",
      "🏦 Caixas eletrônicos em manutenção: 2, 5 e 7",
      "📞 Central de atendimento 24h: 0800-123-4567"
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "min-h-screen transition-all duration-300 pb-16",
      if(@is_dark,
        do: "bg-gradient-to-br from-slate-900 via-blue-950/30 to-indigo-950",
        else: "bg-gradient-to-br from-gray-50 via-slate-50/80 to-gray-100"
      )
    ]}>
      <!-- Merchandise Overlay -->
      <.merchandise_overlay is_visible={@show_merchandise} is_dark={@is_dark} />
      
    <!-- Header -->
      <div class={[
        "backdrop-blur-md border-b px-8 py-4",
        if(@is_dark,
          do: "bg-slate-900/95 border-slate-700/80",
          else: "bg-white/95 border-gray-200/80"
        )
      ]}>
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class={[
              "p-3 rounded-xl",
              if(@is_dark,
                do: "bg-gradient-to-r from-indigo-800 to-blue-800",
                else: "bg-gradient-to-r from-gray-700 to-slate-800"
              )
            ]}>
              <.icon name="hero-computer-desktop" class="w-8 h-8 text-white" />
            </div>
            <div>
              <h1 class={[
                "text-3xl font-bold",
                if(@is_dark, do: "text-slate-100", else: "text-gray-800")
              ]}>
                QMS Dashboard
              </h1>
              <p class={[
                "text-lg",
                if(@is_dark, do: "text-slate-400", else: "text-gray-700")
              ]}>
                Sistema de Gerenciamento de Filas
              </p>
            </div>
          </div>

          <div class="flex items-center space-x-6">
            <div class={[
              "text-right",
              if(@is_dark, do: "text-slate-100", else: "text-gray-800")
            ]}>
              <div class="text-2xl font-bold">
                {format_time(@current_time)}
              </div>
              <div class={[
                "text-sm",
                if(@is_dark, do: "text-slate-400", else: "text-gray-700")
              ]}>
                {format_date(@current_time)}
              </div>
            </div>

            <button
              phx-click="toggle_theme"
              class={[
                "p-3 rounded-lg border transition-colors",
                if(@is_dark,
                  do: "border-slate-600 text-slate-100 hover:bg-slate-700/20",
                  else: "border-gray-600 text-gray-800 hover:bg-gray-200"
                )
              ]}
            >
              <%= if @is_dark do %>
                <.icon name="hero-sun" class="w-5 h-5" />
              <% else %>
                <.icon name="hero-moon" class="w-5 h-5" />
              <% end %>
            </button>

            <button
              phx-click="call_next"
              class={[
                "p-3 rounded-lg border transition-colors",
                if(@is_dark,
                  do: "border-slate-600 text-slate-100 hover:bg-slate-700/20",
                  else: "border-gray-600 text-gray-800 hover:bg-gray-200"
                )
              ]}
            >
              <.icon name="hero-arrow-right" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="px-8 py-6 space-y-6">
        <!-- Current Ticket and Stats -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Current Ticket -->
          <div class={[
            "relative p-1 rounded-xl",
            if(@is_dark,
              do: "bg-gradient-to-r from-blue-900/60 via-slate-800/60 to-indigo-900/60",
              else: "bg-gradient-to-r from-gray-600/40 via-slate-700/40 to-gray-800/40"
            )
          ]}>
            <div
              class={[
                "p-8 rounded-xl",
                if(@is_dark,
                  do: "bg-slate-900/95 backdrop-blur-md border-slate-700/40",
                  else: "bg-white/95 backdrop-blur-md border-gray-200/60"
                )
              ]}
              style={
                if @is_dark do
                  "box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6), 0 15px 35px -5px rgba(0, 0, 0, 0.4);"
                else
                  "box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.35), 0 15px 35px -5px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(255, 255, 255, 0.8);"
                end
              }
            >
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-6">
                  <div class={[
                    "p-4 rounded-xl",
                    if(@is_dark,
                      do: "bg-gradient-to-r from-indigo-800 to-blue-800",
                      else: "bg-gradient-to-r from-gray-700 to-slate-800"
                    )
                  ]}>
                    <!-- Ticket Icon SVG -->
                    <svg
                      class="w-10 h-10 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 11-0-4V7a2 2 0 00-2-2H5z"
                      />
                    </svg>
                  </div>
                  <div>
                    <p class={[
                      "text-3xl font-medium",
                      if(@is_dark, do: "text-slate-300", else: "text-gray-700")
                    ]}>
                      Chamando Agora
                    </p>
                    <h2 class={[
                      "text-8xl font-bold",
                      if(@is_dark, do: "text-slate-100", else: "text-gray-800")
                    ]}>
                      {@current_ticket.number}
                    </h2>
                  </div>
                </div>

                <div class="flex items-center space-x-8">
                  <!-- Arrow Right Icon SVG -->
                  <svg
                    class={[
                      "w-12 h-12",
                      if(@is_dark, do: "text-slate-400", else: "text-gray-600")
                    ]}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 7l5 5m0 0l-5 5m5-5H6"
                    />
                  </svg>

                  <div class="text-center">
                    <p class={[
                      "text-xl font-medium",
                      if(@is_dark, do: "text-slate-300", else: "text-gray-700")
                    ]}>
                      Guichê
                    </p>
                    <h3 class={[
                      "text-8xl font-bold",
                      if(@is_dark, do: "text-slate-100", else: "text-gray-800")
                    ]}>
                      {String.pad_leading(to_string(@current_ticket.counter), 2, "0")}
                    </h3>
                    <div class={[
                      "mt-2 px-3 py-1 rounded-full border text-sm",
                      if(@is_dark,
                        do: "bg-slate-700/40 text-slate-300 border-slate-600/70",
                        else: "bg-gray-300 text-gray-800 border-gray-500"
                      )
                    ]}>
                      {@current_ticket.service}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-4 gap-4 h-full">
            <.stat_card
              title="Pessoas na Fila"
              value={@stats.people_in_queue}
              icon="users"
              is_dark={@is_dark}
            />
            <.stat_card
              title="Tempo Médio"
              value={@stats.average_time}
              icon="clock"
              is_dark={@is_dark}
            />
            <.stat_card
              title="Atendidos Hoje"
              value={@stats.served_today}
              icon="chart"
              is_dark={@is_dark}
            />
            <.stat_card
              title="Guichês Ativos"
              value={@stats.active_counters}
              icon="desktop"
              is_dark={@is_dark}
            />
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
          <!-- Queue and Counters -->
          <div class="lg:col-span-1">
            <.queue_display title="Próximos na Fila" queue_items={@queue_items} is_dark={@is_dark} />
          </div>

          <div class="lg:col-span-2">
            <.service_counters counters={@counters} is_dark={@is_dark} />
          </div>

          <div class="lg:col-span-1">
            <.queue_display title="Senhas chamadas" queue_items={@queue_items} is_dark={@is_dark} />
          </div>
        </div>
      </div>
      
    <!-- News Footer -->
      <.news_footer :if={@show_footer_news} news_items={@news_items} is_dark={@is_dark} />
    </div>
    """
  end
end
