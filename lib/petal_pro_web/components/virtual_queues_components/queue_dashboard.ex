defmodule PetalProWeb.Components.QueueDashboard do
  @moduledoc false
  use Phoenix.Component

  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :icon, :string, required: true
  attr :is_dark, :boolean, default: true

  def stat_card(assigns) do
    ~H"""
    <div class={[
      "relative p-1 rounded-xl h-full",
      if(@is_dark,
        do: "bg-gradient-to-r from-blue-900/60 to-slate-800/60",
        else: "bg-gradient-to-r from-gray-200/70 to-slate-200/70"
      )
    ]}>
      <div
        class={[
          "p-8 rounded-xl h-full relative overflow-hidden",
          if(@is_dark,
            do: "bg-slate-900/95 backdrop-blur-md border-slate-700/80",
            else: "bg-white/95 backdrop-blur-md border-gray-200/80"
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
        <div class="absolute inset-0 flex items-center justify-center">
          <!-- Background Icon -->
          <.icon_svg
            name={@icon}
            class={[
              "w-32 h-32",
              if(@is_dark, do: "text-slate-600/15", else: "text-gray-600/10")
            ]}
          />
        </div>

        <div class="relative z-10 text-center space-y-4 h-full flex flex-col justify-center">
          <!-- Content -->
          <div>
            <p class={[
              "text-xl font-medium",
              if(@is_dark, do: "text-slate-300", else: "text-gray-700")
            ]}>
              {@title}
            </p>
            <p class={[
              "text-7xl font-bold",
              if(@is_dark, do: "text-slate-100", else: "text-gray-800")
            ]}>
              {@value}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :queue_items, :list, required: true
  attr :is_dark, :boolean, default: true
  attr :title, :string, required: true
  attr :max_slots, :integer, default: 5

  def queue_display(assigns) do
    # Create a list with actual items and empty placeholders
    assigns = assign(assigns, :display_items, create_display_items(assigns.queue_items, assigns.max_slots))

    ~H"""
    <div class={[
      "relative p-1 rounded-xl h-full",
      if(@is_dark,
        do: "bg-gradient-to-r from-slate-900/60 via-blue-900/50 to-slate-800/60",
        else: "bg-gradient-to-r from-gray-50/40 via-slate-50/40 to-gray-50/40"
      )
    ]}>
      <div
        class={[
          "h-full rounded-xl",
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
        <div class="p-4 h-full flex flex-col">
          <h3 class={[
            "text-2xl font-bold mb-4",
            if(@is_dark, do: "text-slate-100", else: "text-gray-800")
          ]}>
            {@title}
          </h3>

          <div class="grid grid-cols-1 gap-3 flex-1">
            <%= for {display_item, index} <- Enum.with_index(@display_items) do %>
              <%= if display_item.type == :item do %>
                <!-- Actual queue item -->
                <div
                  class={[
                    "p-4 rounded-lg h-24",
                    if(@is_dark, do: "bg-slate-800/80", else: "bg-gray-50/80")
                  ]}
                  style={
                    if @is_dark do
                      "box-shadow: 0 20px 45px -8px rgba(0, 0, 0, 0.6), 0 12px 25px -6px rgba(0, 0, 0, 0.4);"
                    else
                      "box-shadow: 0 20px 45px -8px rgba(0, 0, 0, 0.25), 0 12px 25px -6px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05);"
                    end
                  }
                >
                  <div class="flex items-center justify-between h-full">
                    <div class={[
                      "w-12 h-12 rounded-full flex items-center justify-center text-lg font-bold",
                      case display_item.item.status do
                        :priority ->
                          if(@is_dark,
                            do: "bg-indigo-800/80 text-indigo-200",
                            else: "bg-gray-700 text-gray-100"
                          )

                        :business ->
                          if(@is_dark,
                            do: "bg-slate-700/80 text-slate-200",
                            else: "bg-gray-600 text-gray-100"
                          )

                        _ ->
                          if(@is_dark,
                            do: "bg-slate-600/80 text-slate-200",
                            else: "bg-gray-500 text-gray-100"
                          )
                      end
                    ]}>
                      {index + 1}
                    </div>

                    <div class={[
                      "text-6xl font-bold flex-1 text-center",
                      if(@is_dark, do: "text-slate-100", else: "text-gray-800")
                    ]}>
                      {display_item.item.ticket}
                    </div>

                    <div class={[
                      "text-sm px-3 py-1 rounded-full border",
                      case display_item.item.status do
                        :priority ->
                          if(@is_dark,
                            do: "bg-indigo-800/90 text-indigo-200 border-indigo-600",
                            else: "bg-gray-700 text-gray-100 border-gray-800"
                          )

                        :business ->
                          if(@is_dark,
                            do: "bg-slate-700/90 text-slate-200 border-slate-500",
                            else: "bg-gray-600 text-gray-100 border-gray-700"
                          )

                        _ ->
                          if(@is_dark,
                            do: "bg-slate-600/90 text-slate-200 border-slate-500",
                            else: "bg-gray-500 text-gray-100 border-gray-600"
                          )
                      end
                    ]}>
                      {case display_item.item.status do
                        :priority -> "Prioritário"
                        :business -> "Empresarial"
                        _ -> "Normal"
                      end}
                    </div>
                  </div>
                </div>
              <% else %>
                <!-- Empty placeholder -->
                <div class={[
                  "border-2 border-dashed rounded-xl h-24 flex items-center justify-center",
                  if(@is_dark,
                    do: "border-gray-600",
                    else: "border-gray-300"
                  )
                ]}>
                  <span class={[
                    "text-sm font-medium opacity-50",
                    if(@is_dark, do: "text-gray-400", else: "text-gray-500")
                  ]}>
                    Posição {index + 1}
                  </span>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper function to create display items with placeholders
  defp create_display_items(queue_items, max_slots) do
    actual_items =
      queue_items
      |> Enum.take(max_slots)
      |> Enum.map(&%{type: :item, item: &1})

    empty_slots = max_slots - length(actual_items)

    empty_items =
      for _ <- 1..empty_slots, do: %{type: :empty}

    actual_items ++ empty_items
  end

  attr :counters, :list, required: true
  attr :is_dark, :boolean, default: true

  def service_counters(assigns) do
    ~H"""
    <div class={[
      "relative p-1 rounded-xl h-full",
      if(@is_dark,
        do: "bg-gradient-to-r from-indigo-900/50 via-slate-800/50 to-blue-900/50",
        else: "bg-gradient-to-r from-gray-50/40 via-slate-50/40 to-gray-50/40"
      )
    ]}>
      <div
        class={[
          "h-full rounded-xl",
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
        <div class="p-4 h-full flex flex-col">
          <h3 class={[
            "text-2xl font-bold mb-4",
            if(@is_dark, do: "text-slate-100", else: "text-gray-800")
          ]}>
            Status dos Guichês
          </h3>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3 flex-1">
            <%= for counter <- @counters do %>
              <div
                class={[
                  "p-3 relative overflow-hidden rounded-lg",
                  case counter.status do
                    :active -> if(@is_dark, do: "bg-slate-800/80", else: "bg-gray-50/80")
                    :break -> if(@is_dark, do: "bg-slate-800/80", else: "bg-gray-100/80")
                    _ -> if(@is_dark, do: "bg-slate-800/80", else: "bg-gray-200/80")
                  end
                ]}
                style={
                  if @is_dark do
                    "box-shadow: 0 20px 45px -8px rgba(0, 0, 0, 0.6), 0 12px 25px -6px rgba(0, 0, 0, 0.4);"
                  else
                    "box-shadow: 0 20px 45px -8px rgba(0, 0, 0, 0.25), 0 12px 25px -6px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05);"
                  end
                }
              >
                
    <!-- Background Icons -->
                <%= if counter.status == :break do %>
                  <div class="absolute inset-0 flex items-center justify-center">
                    <!-- Gift Icon SVG -->
                    <svg
                      class={[
                        "w-24 h-24",
                        if(@is_dark, do: "text-slate-600/15", else: "text-gray-600/10")
                      ]}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"
                      />
                    </svg>
                  </div>
                <% end %>

                <%= if counter.status == :offline do %>
                  <div class="absolute inset-0 flex items-center justify-center">
                    <!-- Power Icon SVG -->
                    <svg
                      class={[
                        "w-24 h-24",
                        if(@is_dark, do: "text-slate-600/15", else: "text-gray-600/10")
                      ]}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5.636 5.636a9 9 0 1012.728 0M12 3v9"
                      />
                    </svg>
                  </div>
                <% end %>

                <div class="flex items-center justify-between mb-2 relative z-10">
                  <div class="flex items-center space-x-2">
                    <!-- Desktop Icon SVG -->
                    <svg
                      class={[
                        "w-6 h-6",
                        case counter.status do
                          :active -> if(@is_dark, do: "text-slate-300", else: "text-gray-700")
                          :break -> if(@is_dark, do: "text-amber-400", else: "text-amber-600")
                          _ -> if(@is_dark, do: "text-slate-500", else: "text-gray-500")
                        end
                      ]}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                      />
                    </svg>
                    <span class={[
                      "text-lg font-bold",
                      if(@is_dark, do: "text-slate-100", else: "text-gray-800")
                    ]}>
                      Guichê {counter.id}
                    </span>
                  </div>

                  <div class={[
                    "text-sm px-3 py-1 rounded-full border",
                    case counter.status do
                      :active ->
                        if(@is_dark,
                          do: "bg-indigo-800/90 text-indigo-200 border-indigo-600",
                          else: "bg-gray-700 text-gray-100 border-gray-800"
                        )

                      :break ->
                        if(@is_dark,
                          do: "bg-amber-700/80 text-amber-200 border-amber-600",
                          else: "bg-amber-600 text-amber-100 border-amber-700"
                        )

                      _ ->
                        if(@is_dark,
                          do: "bg-slate-600/90 text-slate-300 border-slate-500",
                          else: "bg-gray-500 text-gray-100 border-gray-600"
                        )
                    end
                  ]}>
                    {case counter.status do
                      :active -> "Ativo"
                      :break -> "Pausa"
                      _ -> "Offline"
                    end}
                  </div>
                </div>

                <%= if counter.status == :active do %>
                  <div class="text-center space-y-1 relative z-10">
                    <div class={[
                      "text-8xl font-bold",
                      if(@is_dark, do: "text-slate-100", else: "text-gray-800")
                    ]}>
                      {counter.current_ticket}
                    </div>

                    <div class={[
                      "text-xl font-semibold",
                      if(@is_dark, do: "text-slate-400", else: "text-gray-600")
                    ]}>
                      {counter.service}
                    </div>
                  </div>
                <% end %>

                <%= if counter.status == :break do %>
                  <div class={[
                    "text-base text-center relative z-10",
                    if(@is_dark, do: "text-amber-400", else: "text-amber-700")
                  ]}>
                    Em pausa
                  </div>
                <% end %>

                <%= if counter.status == :offline do %>
                  <div class={[
                    "text-base text-center relative z-10",
                    if(@is_dark, do: "text-slate-500", else: "text-gray-500")
                  ]}>
                    Guichê não disponível
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :news_items, :list, required: true
  attr :is_dark, :boolean, default: true

  def news_footer(assigns) do
    ~H"""
    <div class={[
      "fixed bottom-0 left-0 right-0 z-50 overflow-hidden shadow-lg",
      if(@is_dark,
        do: "bg-slate-900/95 backdrop-blur-sm border-t border-slate-700/70",
        else: "bg-white/95 backdrop-blur-sm border-t border-gray-200/60"
      )
    ]}>
      <div class="h-24 flex items-center">
        <div class="flex-1 overflow-hidden">
          <div
            class={[
              "whitespace-nowrap animate-marquee",
              if(@is_dark, do: "text-slate-100", else: "text-gray-800")
            ]}
            style="animation: marquee 60s linear infinite;"
          >
            <span class="text-6xl font-medium">
              {Enum.join(@news_items, " • ")} • {Enum.join(@news_items, " • ")}
            </span>
          </div>
        </div>
      </div>

      <style>
        @keyframes marquee {
          0% { transform: translateX(100%); }
          100% { transform: translateX(-100%); }
        }
        .animate-marquee {
          animation: marquee 60s linear infinite;
        }
      </style>
    </div>
    """
  end

  attr :is_visible, :boolean, default: false
  attr :is_dark, :boolean, default: true

  def merchandise_overlay(assigns) do
    ~H"""
    <%= if @is_visible do %>
      <div class="fixed inset-0 z-40 flex items-center justify-center p-8">
        <!-- Backdrop -->
        <div class={[
          "absolute inset-0",
          if(@is_dark, do: "bg-slate-900/30", else: "bg-white/80")
        ]}>
        </div>
        
    <!-- Overlay Content -->
        <div
          class={[
            "relative w-2/3 h-5/6 rounded-2xl overflow-hidden",
            if(@is_dark,
              do: "bg-gradient-to-br from-slate-800 via-blue-900/95 to-indigo-900",
              else: "bg-gradient-to-br from-white via-gray-50 to-slate-100"
            )
          ]}
          style={
            if @is_dark do
              "box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.8), 0 15px 35px -5px rgba(0, 0, 0, 0.6);"
            else
              "box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.4), 0 15px 35px -5px rgba(0, 0, 0, 0.2), 0 0 0 1px rgba(255, 255, 255, 0.9);"
            end
          }
        >
          <!-- Close Button -->
          <button
            phx-click="close_merchandise"
            class={[
              "absolute top-4 right-4 z-50 p-2 rounded-full transition-colors",
              if(@is_dark,
                do: "bg-slate-700/80 text-slate-200 hover:bg-slate-600",
                else: "bg-gray-200/80 text-gray-700 hover:bg-gray-300"
              )
            ]}
          >
            <!-- X Icon SVG -->
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
          
    <!-- Content Container -->
          <div class="h-full flex">
            <!-- Left Side - Image/Video Area -->
            <div class={[
              "w-3/4 h-full relative",
              if(@is_dark,
                do: "bg-gradient-to-br from-indigo-800/95 to-blue-900/95",
                else: "bg-gradient-to-br from-gray-100 to-slate-200"
              )
            ]}>
              <!-- Placeholder for image/video -->
              <div class="absolute inset-0 flex items-center justify-center">
                <div class={[
                  "text-center space-y-4",
                  if(@is_dark, do: "text-slate-300", else: "text-gray-600")
                ]}>
                  <!-- Play Icon SVG -->
                  <svg class="w-24 h-24 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1m4 0h1m-6 4h1m4 0h1m-6-8h8a2 2 0 012 2v8a2 2 0 01-2 2H8a2 2 0 01-2-2V8a2 2 0 012-2z"
                    />
                  </svg>
                  <p class="text-lg font-medium">Área para Vídeo/Banner</p>
                </div>
              </div>
            </div>
            
    <!-- Right Side - Content Area -->
            <div class="w-1/4 h-full p-8 flex flex-col justify-center">
              <div class="space-y-6">
                <!-- Title -->
                <h2 class={[
                  "text-7xl font-bold",
                  if(@is_dark, do: "text-slate-100", else: "text-gray-800")
                ]}>
                  Novidade!
                </h2>
                
    <!-- Subtitle -->
                <h3 class={[
                  "text-5xl font-semibold",
                  if(@is_dark, do: "text-slate-300", else: "text-gray-700")
                ]}>
                  Confira nosso novo serviço
                </h3>
                
    <!-- Description -->
                <p class={[
                  "text-xl leading-relaxed",
                  if(@is_dark, do: "text-slate-400", else: "text-gray-600")
                ]}>
                  Descubra todas as facilidades que preparamos para você.
                  Atendimento mais rápido, serviços digitais e muito mais.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # Helper component for icons
  attr :name, :string, required: true
  attr :class, :any, default: []

  defp icon_svg(assigns) do
    ~H"""
    <%= case @name do %>
      <% "users" -> %>
        <svg class={@class} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a4 4 0 11-8 0 4 4 0 018 0z"
          />
        </svg>
      <% "clock" -> %>
        <svg class={@class} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
      <% "chart" -> %>
        <svg class={@class} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
          />
        </svg>
      <% "desktop" -> %>
        <svg class={@class} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
          />
        </svg>
      <% _ -> %>
        <div class={@class}></div>
    <% end %>
    """
  end

  # Função auxiliar para formatar horário
  def format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  # Função auxiliar para obter classe de status
  def status_class(status, is_dark) do
    case status do
      :active ->
        if is_dark,
          do: "bg-indigo-800/90 text-indigo-200 border-indigo-600",
          else: "bg-gray-700 text-gray-100 border-gray-800"

      :break ->
        if is_dark,
          do: "bg-amber-700/80 text-amber-200 border-amber-600",
          else: "bg-amber-600 text-amber-100 border-amber-700"

      _ ->
        if is_dark,
          do: "bg-slate-600/90 text-slate-300 border-slate-500",
          else: "bg-gray-500 text-gray-100 border-gray-600"
    end
  end

  # Função auxiliar para obter ícone do status
  def status_icon(status) do
    case status do
      :active -> "hero-computer-desktop"
      :break -> "hero-gift"
      :offline -> "hero-power"
    end
  end

  # Função auxiliar para obter texto do status
  def status_text(status) do
    case status do
      :active -> "Ativo"
      :break -> "Em pausa"
      :offline -> "Guichê não disponível"
    end
  end

  # Função auxiliar para obter classe de prioridade da fila
  def queue_priority_class(status, is_dark) do
    case status do
      :priority ->
        if is_dark, do: "bg-indigo-800/80 text-indigo-200", else: "bg-gray-700 text-gray-100"

      :business ->
        if is_dark, do: "bg-slate-700/80 text-slate-200", else: "bg-gray-600 text-gray-100"

      _ ->
        if is_dark, do: "bg-slate-600/80 text-slate-200", else: "bg-gray-500 text-gray-100"
    end
  end

  # Função auxiliar para obter badge de prioridade
  def queue_badge_class(status, is_dark) do
    case status do
      :priority ->
        if is_dark,
          do: "bg-indigo-800/90 text-indigo-200 border-indigo-600",
          else: "bg-gray-700 text-gray-100 border-gray-800"

      :business ->
        if is_dark,
          do: "bg-slate-700/90 text-slate-200 border-slate-500",
          else: "bg-gray-600 text-gray-100 border-gray-700"

      _ ->
        if is_dark,
          do: "bg-slate-600/90 text-slate-200 border-slate-500",
          else: "bg-gray-500 text-gray-100 border-gray-600"
    end
  end

  # Função auxiliar para obter texto de prioridade
  def priority_text(status) do
    case status do
      :priority -> "Prioritário"
      :business -> "Empresarial"
      _ -> "Normal"
    end
  end
end
