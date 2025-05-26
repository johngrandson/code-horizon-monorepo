defmodule PetalProWeb.OrgDashboardLive do
  @moduledoc """
  Show a responsive dashboard for a single org. Current user must be a member of the org.
  """
  use PetalProWeb, :live_view

  import PetalProWeb.OrgLayoutComponent

  alias PetalPro.Orgs.Membership

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(is_org_admin: Membership.is_org_admin?(socket.assigns.current_user))
      |> assign(health_status: :up)
      |> assign(page_title: socket.assigns.current_org.name)
      |> assign(total_members: Membership.org_members_count(socket.assigns.current_org))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.org_layout
      current_page={:org_dashboard}
      current_user={@current_user}
      current_org={@current_org}
      current_membership={@current_membership}
      socket={@socket}
    >
      <div class="min-h-screen">
        <.container class="py-4 sm:py-6 lg:py-8">
          <main id="content" class="space-y-6 sm:space-y-8">
            <.org_profile_header org={@current_org} />
            <.stats_grid
              total_members={@total_members}
              current_org={@current_org}
              health_status={@health_status}
            />
            <div :if={@is_org_admin} class="grid grid-cols-1 xl:grid-cols-2 gap-6 lg:gap-8">
              <.profile_setup_card />
            </div>
            <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 lg:gap-8">
              <.sales_chart_card />
              <.revenue_chart_section current_org={@current_org} />
            </div>
          </main>
        </.container>
      </div>
    </.org_layout>
    """
  end

  # Organization Profile Header Component
  defp org_profile_header(assigns) do
    ~H"""
    <div class="relative">
      <div class="flex flex-col items-center space-y-4 sm:flex-row sm:items-center sm:space-y-0 sm:space-x-6 p-4 sm:p-6 bg-white dark:bg-neutral-900 rounded-xl">
        <!-- Avatar Section -->
        <div class="relative shrink-0">
          <div class="w-16 h-16 sm:w-20 sm:h-20 lg:w-24 lg:h-24 rounded-full overflow-hidden bg-gray-200 dark:bg-neutral-700">
            <%= if @org.avatar_url do %>
              <img class="w-full h-full object-cover" src={@org.avatar_url} alt={@org.name} />
            <% else %>
              <.avatar class="w-full h-full" />
            <% end %>
          </div>
          <%= if @org.is_enterprise do %>
            <.pro_badge class="absolute top-14" />
          <% end %>
        </div>

        <div class="flex-1 text-center sm:text-left space-y-2">
          <h1 class="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-900 dark:text-white">
            {@org.name}
          </h1>
          <div class="flex items-center justify-center sm:justify-start space-x-2 text-gray-500 dark:text-neutral-400">
            <.icon name="hero-link" class="w-4 h-4" />
            <span class="text-sm">{@org.slug}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Statistics Grid Component
  defp stats_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6">
      <.stat_card
        title={gettext("Total members")}
        value={@total_members}
        icon="hero-users"
        link_text={gettext("View members")}
        navigate="#"
      />

      <.stat_card
        title={gettext("Active Modules")}
        value="5"
        icon="hero-cube"
        link_text={gettext("View modules")}
        navigate="#"
      />

      <.stat_card
        title={gettext("Health Status")}
        value={if @health_status == :up, do: gettext("Up"), else: gettext("Down")}
        icon={if @health_status == :up, do: "hero-bolt", else: "hero-bolt-slash"}
        link_text={gettext("View status")}
        navigate="#"
        status_indicator={@health_status}
      />

      <.stat_card
        title={gettext("Pending Invitations")}
        value={Membership.pending_invitations_count(@current_org)}
        icon="hero-user-plus"
        link_text={gettext("View Invitations")}
        navigate={~p"/app/org/#{@current_org.slug}/team"}
      />
    </div>
    """
  end

  # Individual Stat Card Component
  defp stat_card(assigns) do
    assigns = assign_new(assigns, :status_indicator, fn -> nil end)

    ~H"""
    <.link
      navigate={@navigate}
      class="group relative overflow-hidden bg-white dark:bg-neutral-900 border border-gray-200 dark:border-neutral-700 rounded-xl p-4 lg:p-6 hover:shadow-sm hover:-translate-y-1 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-200"
    >
      <!-- Status Indicator -->
      <%= if @status_indicator do %>
        <div class="absolute top-3 right-3">
          <div class={[
            "w-2 h-2 rounded-full",
            @status_indicator == :up && "bg-green-500",
            @status_indicator == :down && "bg-red-500"
          ]}>
          </div>
        </div>
      <% end %>

      <div class="flex items-start justify-between space-x-4">
        <div class="flex-1 min-w-0">
          <h3 class="text-xs font-medium text-gray-600 dark:text-neutral-400 uppercase tracking-wide">
            {@title}
          </h3>
          <p class="mt-2 text-xl sm:text-2xl font-bold text-gray-900 dark:text-white truncate">
            {@value}
          </p>
        </div>
        <.icon
          name={@icon}
          class="w-5 h-5 sm:w-6 sm:h-6 text-gray-400 dark:text-neutral-500 shrink-0"
        />
      </div>

      <div class="mt-4 flex items-center text-sm text-blue-600 dark:text-blue-400 group-hover:text-blue-700 dark:group-hover:text-blue-300">
        <span class="font-medium">{@link_text}</span>
        <.icon
          name="hero-arrow-right"
          class="ml-2 w-4 h-4 transition-transform group-hover:translate-x-1"
        />
      </div>
    </.link>
    """
  end

  # Profile Setup Card Component
  defp profile_setup_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-neutral-900 border border-gray-200 dark:border-neutral-700 rounded-xl p-4 sm:p-6 lg:p-8">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg sm:text-xl font-bold text-gray-900 dark:text-white">
          {gettext("Profile setup")}
        </h2>
        <div class="text-right">
          <div class="text-xs text-gray-500 dark:text-neutral-400 mb-1">2 of 4 completed</div>
          <div class="flex space-x-1">
            <div class="w-3 h-1.5 bg-green-500 rounded-full"></div>
            <div class="w-3 h-1.5 bg-green-500 rounded-full"></div>
            <div class="w-3 h-1.5 bg-gray-200 dark:bg-neutral-600 rounded-full"></div>
            <div class="w-3 h-1.5 bg-gray-200 dark:bg-neutral-600 rounded-full"></div>
          </div>
        </div>
      </div>
      
    <!-- Progress Description -->
      <p class="text-sm text-gray-600 dark:text-neutral-400 mb-6">
        Your profile needs to be at least
        <span class="font-semibold text-gray-900 dark:text-white">50% complete</span>
        to be publicly visible.
      </p>
      
    <!-- Setup Items -->
      <div class="space-y-3">
        <.setup_item
          title="Download desktop app"
          completed={true}
          button_text="Download"
          disabled={true}
        />

        <.setup_item
          title="Provide company details"
          completed={false}
          button_text="Add now"
          disabled={false}
        />

        <.setup_item title="Invite 5 talents" completed={true} button_text="Invite" disabled={true} />

        <.setup_item title="Add projects" completed={false} button_text="Add now" disabled={false} />
      </div>
    </div>
    """
  end

  # Setup Item Component
  defp setup_item(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-neutral-700 rounded-lg">
      <div class="flex items-center space-x-3">
        <!-- Status Icon -->
        <div class={[
          "w-5 h-5 rounded-full flex items-center justify-center",
          @completed && "bg-green-500 text-white",
          !@completed && "border-2 border-gray-300 dark:border-neutral-500"
        ]}>
          <%= if @completed do %>
            <.icon name="hero-check" class="w-3 h-3" />
          <% end %>
        </div>
        
    <!-- Title -->
        <span class={[
          "text-sm font-medium",
          @completed && "line-through text-gray-400 dark:text-neutral-500",
          !@completed && "text-gray-900 dark:text-white"
        ]}>
          {@title}
        </span>
      </div>
      
    <!-- Action Button -->
      <button
        type="button"
        disabled={@disabled}
        class="px-3 py-1.5 text-xs font-medium text-gray-700 dark:text-neutral-300 bg-white dark:bg-neutral-600 border border-gray-200 dark:border-neutral-500 rounded-md hover:bg-gray-50 dark:hover:bg-neutral-500 disabled:opacity-50 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 transition-colors"
      >
        {@button_text}
      </button>
    </div>
    """
  end

  # Sales Chart Card Component
  defp sales_chart_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-neutral-900 border border-gray-200 dark:border-neutral-700 rounded-xl p-4 sm:p-6 lg:p-8">
      <!-- Header with Date Picker -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 space-y-4 sm:space-y-0">
        <h2 class="text-lg sm:text-xl font-bold text-gray-900 dark:text-white">
          Total sales
        </h2>
        <.date_picker_button />
      </div>
      
    <!-- Sales Amount -->
      <div class="mb-8">
        <h4 class="text-3xl sm:text-4xl font-bold text-gray-900 dark:text-white">
          <span class="text-lg text-gray-500 dark:text-neutral-400 align-top">$</span>43,350
        </h4>
      </div>
      
    <!-- Sales Breakdown -->
      <div class="space-y-4 mb-8">
        <.sales_item
          color="bg-blue-600"
          label="Store sales"
          amount="$51,392"
          change="38.2%"
          trend="up"
        />

        <.sales_item
          color="bg-purple-600"
          label="Online sales"
          amount="$46,420"
          change="5.9%"
          trend="up"
        />

        <.sales_item
          color="bg-gray-300 dark:bg-neutral-500"
          label="Others"
          amount="$39,539"
          change="3.1%"
          trend="down"
        />
      </div>
      
    <!-- Chart Container -->
      <div id="org-dashboard-chart" phx-hook="OrgDashboardChartHook" class="min-h-[120px] w-full">
      </div>
    </div>
    """
  end

  # Date Picker Button Component
  defp date_picker_button(assigns) do
    ~H"""
    <button
      type="button"
      class="inline-flex items-center px-3 py-2 text-xs font-medium text-gray-700 dark:text-neutral-300 bg-white dark:bg-neutral-700 border border-gray-200 dark:border-neutral-600 rounded-lg hover:bg-gray-50 dark:hover:bg-neutral-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 transition-colors"
    >
      <.icon name="hero-calendar-days" class="w-4 h-4 mr-2" /> Today
      <.icon name="hero-chevron-down" class="w-4 h-4 ml-2" />
    </button>
    """
  end

  # Sales Item Component
  defp sales_item(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-3">
        <div class={["w-2.5 h-2.5 rounded-sm", @color]}></div>
        <span class="text-sm text-gray-600 dark:text-neutral-400">{@label}</span>
      </div>

      <div class="flex items-center space-x-3 text-sm">
        <span class="font-medium text-gray-900 dark:text-white">{@amount}</span>
        <div class={[
          "flex items-center space-x-1",
          @trend == "up" && "text-green-600 dark:text-green-400",
          @trend == "down" && "text-red-600 dark:text-red-400"
        ]}>
          <.icon
            name={if @trend == "up", do: "hero-arrow-trending-up", else: "hero-arrow-trending-down"}
            class="w-4 h-4"
          />
          <span>{@change}</span>
        </div>
      </div>
    </div>
    """
  end

  # Revenue Chart Section Component
  defp revenue_chart_section(assigns) do
    ~H"""
    <div class="bg-white dark:bg-neutral-900 border border-gray-200 dark:border-neutral-700 rounded-xl p-4 sm:p-6 lg:p-8">
      <div class="mb-6">
        <h2 class="text-lg sm:text-xl font-bold text-gray-900 dark:text-white">
          Revenue Overview
        </h2>
      </div>

      <.live_component
        module={PetalProWeb.Components.Charts.RevenueChart}
        id="revenue-chart"
        current_org={@current_org}
      />
    </div>
    """
  end
end
