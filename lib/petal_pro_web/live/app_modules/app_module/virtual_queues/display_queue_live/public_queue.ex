defmodule PetalProWeb.VirtualQueues.DisplayQueueLive.PublicQueue do
  @moduledoc """
  LiveView implementation for the enhanced Queue Dashboard.
  Handles real-time updates, notifications, and user interactions.
  """
  use PetalProWeb, :live_view

  import PetalProWeb.Components.QueueDashboard

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
      :timer.send_interval(60_000, self(), :toggle_news)
    end

    socket =
      socket
      |> assign(:current_time, DateTime.now!("America/Sao_Paulo"))
      |> assign(:is_dark, true)
      |> assign(:show_merchandise, false)
      |> assign(:show_news, false)
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
      |> assign(:counters, [
        %{id: 1, status: :active, current_ticket: "A047", service: "Atendimento Geral"},
        %{id: 2, status: :active, current_ticket: "B011", service: "Atendimento Prioritário"},
        %{id: 3, status: :active, current_ticket: "C004", service: "Atendimento Empresarial"},
        %{id: 4, status: :break, current_ticket: nil, service: nil},
        %{id: 5, status: :active, current_ticket: "A046", service: "Atendimento Geral"},
        %{id: 6, status: :active, current_ticket: "B010", service: "Atendimento Prioritário"},
        %{id: 7, status: :offline, current_ticket: nil, service: nil},
        %{id: 8, status: :offline, current_ticket: nil, service: nil}
      ])
      |> assign(:stats, %{
        people_in_queue: 24,
        average_time: "8min",
        served_today: 142,
        active_counters: "6/8"
      })
      |> assign(:news_items, [
        "🔔 Lembrete: O atendimento será encerrado às 17h hoje",
        "📋 Novos documentos necessários para abertura de conta corrente disponíveis no site",
        "⏰ Horário especial de funcionamento no feriado: 8h às 12h",
        "💳 Cartões com chip serão entregues em até 5 dias úteis",
        "📱 Baixe nosso aplicativo e evite filas desnecessárias",
        "🏦 Caixas eletrônicos em manutenção: 2, 5 e 7",
        "📞 Central de atendimento 24h: 0800-123-4567"
      ])

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, :current_time, DateTime.now!("America/Sao_Paulo"))}
  end

  @impl true
  def handle_info(:toggle_news, socket) do
    {:noreply, assign(socket, :show_news, !socket.assigns.show_news)}
  end

  @impl true
  def handle_event("toggle_theme", _params, socket) do
    {:noreply, assign(socket, :is_dark, !socket.assigns.is_dark)}
  end

  @impl true
  def handle_event("close_merchandise", _params, socket) do
    {:noreply, assign(socket, :show_merchandise, false)}
  end

  @impl true
  def handle_event("show_merchandise", _params, socket) do
    {:noreply, assign(socket, :show_merchandise, true)}
  end

  # Função para simular chamada de próximo ticket
  @impl true
  def handle_event("call_next", _params, socket) do
    # Aqui você implementaria a lógica de chamar próximo ticket
    # Por agora, apenas simulamos mudando o ticket atual
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
              <!-- Monitor Icon SVG -->
              <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
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
                <!-- Sun Icon SVG -->
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
                  />
                </svg>
              <% else %>
                <!-- Moon Icon SVG -->
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
                  />
                </svg>
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
              <.icon name="hero-arrow-right" />
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
        
    <!-- Queue and Counters -->
        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
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
      <.news_footer :if={@show_news} news_items={@news_items} is_dark={@is_dark} />
    </div>
    """
  end
end
