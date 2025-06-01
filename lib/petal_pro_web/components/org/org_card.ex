defmodule PetalProWeb.Components.OrgCard do
  @moduledoc """
  Organization card component with enhanced design for use in grid layouts.
  """
  use Phoenix.Component
  use PetalProWeb, :verified_routes
  use Gettext, backend: PetalProWeb.Gettext
  use PetalComponents

  import PetalProWeb.CoreComponents

  attr :org, :map, required: true
  attr :current_user, :map, required: true
  attr :socket, :any, default: nil

  def org_card(assigns) do
    assigns = assign(assigns, :is_org_admin, is_org_admin?(assigns.org, assigns.current_user))

    ~H"""
    <div class="flex flex-col h-full">
      <!-- Gradient Header -->
      <figure class="shrink-0 relative h-24 overflow-hidden rounded-t-xl">
        <svg
          class="w-full h-24 rounded-t-xl"
          preserveAspectRatio="xMidYMid slice"
          width="576"
          height="120"
          viewBox="0 0 576 120"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g clip-path={"url(##{@org.id}_clip0)"}>
            <rect width="576" height="120" fill="#B2E7FE" />
            <rect
              x="289.678"
              y="-90.3"
              width="102.634"
              height="391.586"
              transform="rotate(59.5798 289.678 -90.3)"
              fill="#FF8F5D"
            />
            <rect
              x="41.3926"
              y="-0.996094"
              width="102.634"
              height="209.864"
              transform="rotate(-31.6412 41.3926 -0.996094)"
              fill="#3ECEED"
            />
            <rect
              x="66.9512"
              y="40.4817"
              width="102.634"
              height="104.844"
              transform="rotate(-31.6412 66.9512 40.4817)"
              fill="#4C48FF"
            />
          </g>
          <defs>
            <clipPath id={"#{@org.id}_clip0"}>
              <rect width="576" height="120" fill="white" />
            </clipPath>
          </defs>
        </svg>
      </figure>
      
    <!-- Avatar Section -->
      <div class="-mt-8 px-4 mb-3">
        <div class="relative flex items-center gap-x-3">
          <div class="relative w-20">
            <%= if @org.avatar_url do %>
              <img
                class="shrink-0 size-20 ring-4 ring-white rounded-3xl dark:ring-neutral-800 object-cover"
                src={@org.avatar_url}
                alt={@org.name}
              />
            <% else %>
              <div class="shrink-0 size-20 ring-4 ring-white rounded-3xl dark:ring-neutral-800 bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                <span class="text-white font-bold text-xl">
                  {String.first(@org.name)}
                </span>
              </div>
            <% end %>

            <%= if Map.get(@org, :is_enterprise, false) do %>
              <div class="absolute -bottom-0 inset-x-0 text-center">
                <span class="py-1 px-2 inline-flex items-center gap-x-1 text-xs font-semibold uppercase rounded-md text-white shadow-sm">
                  <.pro_badge />
                </span>
              </div>
            <% end %>
          </div>
          
    <!-- Action Buttons -->
          <div class="absolute bottom-2 end-0">
            <div class="flex justify-end items-end gap-x-2">
              <button
                type="button"
                phx-click="toggle_favorite"
                phx-value-org_id={@org.id}
                class="flex justify-center items-center gap-x-3 size-8 text-sm border border-gray-200 text-gray-600 hover:bg-gray-100 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-none focus:bg-gray-100 dark:border-neutral-700 dark:text-neutral-400 dark:hover:bg-neutral-700 dark:focus:bg-neutral-700 dark:hover:text-neutral-200 dark:focus:text-neutral-200 transition-all duration-200"
                title={gettext("Add to favorites")}
              >
                <.icon name="hero-star" class="w-3.5 h-3.5" />
                <span class="sr-only">Add to favorites</span>
              </button>

              <.org_actions org={@org} />
            </div>
          </div>
        </div>
      </div>
      
    <!-- Card Body -->
      <div class="flex-1 px-4 pb-4">
        <h2 class="mb-3 font-semibold text-gray-900 dark:text-white truncate text-lg">
          {@org.name}
        </h2>
        
    <!-- Organization Details -->
        <dl class="space-y-2">
          <div class="flex items-center justify-between">
            <dt class="text-sm text-gray-500 dark:text-neutral-400">
              {gettext("Role")}
            </dt>
            <dd class="flex items-center gap-1.5">
              <span class={"w-2 h-2 rounded-full #{if @is_org_admin, do: "bg-emerald-500", else: "bg-blue-500"}"} />
              <span class="text-sm font-medium text-gray-900 dark:text-white">
                <%= if @is_org_admin do %>
                  {gettext("Admin")}
                <% else %>
                  {gettext("Member")}
                <% end %>
              </span>
            </dd>
          </div>

          <div class="flex items-center justify-between">
            <dt class="text-sm text-gray-500 dark:text-neutral-400">
              {gettext("Status")}
            </dt>
            <dd class="flex items-center gap-1.5">
              <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
              <span class="text-sm font-medium text-gray-900 dark:text-white">
                {gettext("Active")}
              </span>
            </dd>
          </div>

          <div class="flex items-center justify-between">
            <dt class="text-sm text-gray-500 dark:text-neutral-400">
              {gettext("Slug")}
            </dt>
            <dd class="text-sm font-mono text-gray-700 dark:text-neutral-300 truncate max-w-32">
              {@org.slug}
            </dd>
          </div>
          
    <!-- Member Count -->
          <div class="flex items-center justify-between">
            <dt class="text-sm text-gray-500 dark:text-neutral-400">
              {gettext("Members")}
            </dt>
            <dd class="flex items-center gap-1.5">
              <.icon name="hero-users" class="w-3 h-3 text-gray-400" />
              <span class="text-sm font-medium text-gray-900 dark:text-white">
                {Map.get(@org, :member_count, 0)}
              </span>
            </dd>
          </div>
        </dl>
        
    <!-- Tags/Features -->
        <%= if tags = get_org_tags(@org) do %>
          <div class="mt-3">
            <div class="flex flex-wrap gap-1">
              <%= for tag <- Enum.take(tags, 2) do %>
                <span class="py-1 px-2 text-xs font-medium bg-blue-50 text-blue-700 rounded-md dark:bg-blue-900/30 dark:text-blue-300">
                  {tag}
                </span>
              <% end %>
              <%= if length(tags) > 2 do %>
                <span class="py-1 px-2 text-xs font-medium bg-gray-100 text-gray-600 rounded-md dark:bg-neutral-700 dark:text-neutral-400">
                  +{length(tags) - 2}
                </span>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
      
    <!-- Card Footer -->
      <div class="p-4 border-t border-gray-200 dark:border-neutral-700">
        <.link
          navigate={~p"/app/org/#{@org.slug}"}
          class="w-full flex justify-center items-center gap-2 py-2.5 px-4 bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white font-medium text-sm rounded-lg shadow-sm transition-all duration-200 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          {gettext("View organization")}
          <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
        </.link>
      </div>
    </div>
    """
  end

  defp org_actions(assigns) do
    ~H"""
    <div
      class="flex justify-center items-center gap-x-3 size-8 text-sm border border-gray-200 text-gray-600 hover:bg-gray-100 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-none focus:bg-gray-100 dark:border-neutral-700 dark:text-neutral-400 dark:hover:bg-neutral-700 dark:focus:bg-neutral-700 dark:hover:text-neutral-200 dark:focus:text-neutral-200 transition-all duration-200"
      id={"org_actions_container_#{@org.id}"}
    >
      <.dropdown
        class="dark:shadow-lg"
        options_container_id={"org_options_#{@org.id}"}
        menu_items_wrapper_class="dark:border dark:border-gray-600"
      >
        <.dropdown_menu_item link_type="live_redirect" to={~p"/app/org/#{@org.slug}"}>
          <.icon name="hero-information-circle" class="w-5 h-5" /> {gettext("View")}
        </.dropdown_menu_item>
        <.dropdown_menu_item link_type="live_patch" to={~p"/app/org/#{@org.slug}/edit"}>
          <.icon name="hero-pencil" class="w-5 h-5" /> {gettext("Edit")}
        </.dropdown_menu_item>
        <.dropdown_menu_item
          link_type="a"
          to="#"
          phx-click="delete"
          phx-value-id={@org.id}
          data-confirm={gettext("Are you sure?")}
        >
          <.icon name="hero-trash" class="w-5 h-5" /> {gettext("Delete")}
        </.dropdown_menu_item>
      </.dropdown>
    </div>
    """
  end

  # Helper function to check if user is org admin
  defp is_org_admin?(org, _user) do
    # Check if user has admin role in this organization
    # This would typically query the membership table
    case Map.get(org, :current_membership) do
      %{role: :admin} -> true
      _ -> false
    end
  end

  # Helper function to get organization tags/features
  defp get_org_tags(org) do
    tags = []

    tags = if Map.get(org, :is_enterprise), do: ["Enterprise" | tags], else: tags
    tags = if Map.get(org, :has_billing), do: ["Billing" | tags], else: tags
    tags = if Map.get(org, :has_custom_domain), do: ["Custom Domain" | tags], else: tags

    case length(tags) do
      0 -> nil
      _ -> tags
    end
  end
end
