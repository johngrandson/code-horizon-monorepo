defmodule PetalProWeb.OrgsLive.Index do
  @moduledoc """
  List all orgs for the current_user with improved styling and user experience.
  """
  use PetalProWeb, :live_view

  import PetalPro.Events.Modules.Orgs.Subscriber

  alias PetalPro.Orgs
  alias PetalPro.Orgs.Membership
  alias PetalProWeb.DataTable

  require Logger

  @data_table_opts [
    default_limit: 50,
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    },
    sortable: [:id, :slug, :name, :address, :inserted_at],
    filterable: [:id, :slug, :name, :address]
  ]

  @impl true
  def mount(_params, _session, socket) do
    is_org_admin = Membership.is_org_admin?(socket.assigns.current_user)

    socket =
      socket
      |> assign(index_params: nil)
      |> assign(:is_org_admin, is_org_admin)
      |> assign_invitations()
      |> register_subscriber()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    socket
    |> assign(:page_title, gettext("Edit %{model}", model: gettext("Organization")))
    |> assign(:org, slug |> Orgs.get_org!() |> Orgs.preload_org_memberships())
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New %{model}", model: gettext("Organization")))
    |> assign(:org, %Orgs.Org{})
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, gettext("Organizations"))
    |> assign_orgs(params)
    |> assign(index_params: params)
  end

  defp current_index_path(index_params) do
    ~p"/app/orgs?#{index_params || %{}}"
  end

  @impl true
  def handle_info({:invitation_sent, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket =
      assign_invitations(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:invitation_deleted, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket =
      assign_invitations(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = DataTable.build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: current_index_path(query_params))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org = Orgs.get_org_by_id!(id)
    {:ok, _} = Orgs.delete_org(org)

    socket =
      socket
      |> assign_orgs(socket.assigns.index_params)
      |> put_flash(:info, gettext("%{model} successfully deleted", model: gettext("Organization")))

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, patch_back_to_index(socket)}
  end

  defp assign_invitations(socket) do
    assign(socket, :invitations, Orgs.list_invitations_by_user(socket.assigns.current_user))
  end

  defp assign_orgs(socket, params) do
    starting_query =
      Orgs.Org.by_user(socket.assigns.current_user)

    {orgs, meta} = DataTable.search(starting_query, params, @data_table_opts)
    assign(socket, orgs: orgs, meta: meta)
  end

  defp get_org_tags(org) do
    if org.is_enterprise, do: [gettext("Enterprise")], else: [gettext("Regular")]
  end

  defp patch_back_to_index(socket) do
    push_patch(socket, to: ~p"/app/orgs?#{socket.assigns[:index_params] || %{}}")
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

  @impl true
  def render(assigns) do
    ~H"""
    <.layout current_page={:orgs} current_user={@current_user} type="sidebar">
      <.container class="py-4">
        {render_header(assigns)}
        {render_content(assigns)}
      </.container>
      {render_modal(assigns)}
    </.layout>
    """
  end

  defp render_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
      <.page_header
        title={gettext("Organizations")}
        description={gettext("Manage your organizations")}
      />
      <%= if @current_user.confirmed_at && @is_org_admin do %>
        <.button
          link_type="live_redirect"
          color="primary"
          to={~p"/app/orgs/new"}
          class="mt-4 md:mt-0 transition-all hover:scale-105"
        >
          <.icon name="hero-plus" class="w-5 h-5 mr-2" />
          {gettext("Create organization")}
        </.button>
      <% end %>
    </div>
    """
  end

  defp render_content(%{live_action: :index} = assigns) do
    ~H"""
    <div>
      {render_invitations(assigns)}
      {render_organizations(assigns)}
    </div>
    """
  end

  defp render_content(_assigns), do: nil

  defp render_invitations(%{invitations: []}), do: nil

  defp render_invitations(assigns) do
    ~H"""
    <div
      id="hs-pro-shchal"
      class="mb-5 p-4 sm:ps-16 relative overflow-hidden rounded-lg bg-blue-50 dark:bg-blue-900"
      role="alert"
      tabindex="-1"
      aria-labelledby="hs-pro-shchal-label"
    >
      <div class="flex items-center gap-x-3">
        <div class="hidden sm:block absolute -bottom-4 -start-6">
          <span class="text-7xl">📩</span>
        </div>
        <div class="grow ml-2">
          <h4 id="hs-pro-shchal-label" class="font-medium text-blue-700 dark:text-white">
            {gettext("You have %{count} %{plural}",
              count: length(@invitations),
              plural: ngettext("invitation", "invitations", length(@invitations))
            )}
          </h4>
          <p class="mt-1 text-xs text-gray-800 dark:text-neutral-200">
            {gettext("You have pending invitations to join other organizations.")}
          </p>
        </div>
        <.button
          color="primary"
          link_type="live_redirect"
          to={~p"/app/users/org-invitations"}
          class="transition-all hover:translate-x-1"
        >
          {gettext("View invitations")}
          <.icon name="hero-arrow-right" class="w-4 h-4 ml-2" />
        </.button>
      </div>
    </div>
    """
  end

  defp render_organizations(%{orgs: []} = assigns) do
    ~H"""
    <div class="bg-white dark:bg-neutral-900 rounded-xl shadow-sm border border-gray-200 dark:border-neutral-700 p-8 mb-8">
      <div class="text-center">
        <.icon
          name="hero-building-office-2"
          class="w-16 h-16 mx-auto text-gray-400 dark:text-neutral-500"
        />

        <.h3 class="mt-4 text-lg font-medium text-gray-900 dark:text-white">
          {gettext("No organizations yet")}
        </.h3>

        <p class="mt-2 text-gray-500 dark:text-gray-400 max-w-sm mx-auto">
          <%= if @is_org_admin do %>
            {gettext(
              "Create your first organization to collaborate with your team and manage resources together."
            )}
          <% else %>
            {gettext(
              "Join an organization to collaborate with your team and manage resources together."
            )}
          <% end %>
        </p>

        <%= if @is_org_admin do %>
          <.button
            link_type="live_redirect"
            color="primary"
            size="lg"
            to={~p"/app/orgs/new"}
            class="mt-6 transition-all hover:scale-105"
          >
            <.icon name="hero-plus" class="w-5 h-5 mr-2" />
            {gettext("Create your first organization")}
          </.button>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_organizations(assigns) do
    ~H"""
    <div class="pt-2 md:pt-4 pb-10">
      <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 xl:gap-6">
        <%= for org <- @orgs do %>
          <.organization_card org={org} is_org_admin={@is_org_admin} socket={@socket} />
        <% end %>
      </div>

      <%= if length(@orgs) > 9 do %>
        <div class="mt-5">
          <div class="grid grid-cols-2 items-center gap-y-2 sm:gap-y-0 sm:gap-x-5">
            <p class="text-sm text-gray-800 dark:text-neutral-200">
              <span class="font-medium">{length(@orgs)}</span>
              <span class="text-gray-500 dark:text-neutral-500">
                {gettext("organizations")}
              </span>
            </p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_modal(%{live_action: action} = assigns) when action in [:new, :edit] do
    ~H"""
    <.modal title={@page_title} max_width="lg">
      <.live_component
        module={PetalProWeb.OrgFormComponent}
        id={@org.id || :new}
        action={@live_action}
        org={@org}
        return_to={current_index_path(@index_params)}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  defp render_modal(_assigns), do: nil

  defp organization_card(assigns) do
    ~H"""
    <div class="flex flex-col bg-white border border-gray-200 rounded-xl dark:bg-neutral-800 dark:border-neutral-700 hover:shadow-lg transition-all duration-300">
      <!-- Header with gradient background -->
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
                <span class="text-white font-bold text-5xl">
                  {String.first(@org.name)}
                </span>
              </div>
            <% end %>

            <%= if @org.is_enterprise do %>
              <div class="absolute -bottom-3 inset-x-0 text-center">
                <span class="py-1 px-2 inline-flex items-center gap-x-1 text-xs font-semibold uppercase rounded-md bg-gradient-to-tr from-lime-500 to-teal-500 text-white">
                  Pro
                </span>
              </div>
            <% end %>
          </div>

          <div class="absolute bottom-2 end-0">
            <!-- Action Buttons -->
            <div class="flex justify-end items-end gap-x-2">
              <!-- Favorite Button -->
              <.button
                phx-click="toggle_favorite"
                data-tippy-content={gettext("Add to favorites")}
                phx-hook="TippyHook"
                phx-value-org_id={@org.id}
                class="flex justify-center items-center bg-transparent border p-2 border-gray-200 text-gray-600 hover:bg-gray-100 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:border-neutral-700 dark:text-neutral-400 dark:hover:bg-neutral-700 dark:focus:bg-neutral-700 dark:hover:text-neutral-200 dark:focus:text-neutral-200 transition-all duration-200"
              >
                <.icon name="hero-star" class="w-3.5 h-3.5" />
                <span class="sr-only">Add to favorites</span>
              </.button>

              <div class="hover:pointer-events-auto">
                <.org_actions socket={@socket} org={@org} />
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Card Body -->
      <div class="p-4 h-full">
        <h2 class="mb-2 font-medium text-gray-800 dark:text-neutral-300 truncate">
          {@org.name}
        </h2>
        
    <!-- Organization Details List -->
        <dl class="grid grid-cols-2 gap-x-2 mb-3">
          <dt class="py-1 text-sm text-gray-500 dark:text-neutral-500">
            {gettext("Role")}:
          </dt>
          <dd class="py-1 inline-flex justify-end items-center gap-x-2 text-end font-medium text-sm text-gray-800 dark:text-neutral-200">
            <div class="flex items-center gap-x-1.5 py-0.5 px-2 border border-gray-200 dark:border-neutral-700 rounded-md">
              <span class="w-1 h-3 rounded-full bg-teal-600 dark:bg-teal-400" />
              <span class="font-medium text-[13px] text-gray-800 dark:text-neutral-200">
                <%= if @is_org_admin do %>
                  {gettext("Admin")}
                <% else %>
                  {gettext("Member")}
                <% end %>
              </span>
            </div>
          </dd>

          <dt class="py-1 text-sm text-gray-500 dark:text-neutral-500">
            {gettext("Slug")}:
          </dt>
          <dd class="py-1 inline-flex items-center gap-x-2 text-end font-medium text-sm text-gray-800 dark:text-neutral-200 truncate">
            {@org.slug}
          </dd>

          <dt class="py-1 text-sm text-gray-500 dark:text-neutral-500">
            {gettext("Status")}:
          </dt>
          <dd class="py-1 inline-flex justify-end items-center gap-x-2 text-end">
            <span class="font-medium text-[13px] text-gray-800 dark:text-neutral-200">
              {gettext("Active")}
            </span>
          </dd>
          
    <!-- Tags Group -->
          <dt class="py-1 text-sm text-gray-500 dark:text-neutral-500">
            {gettext("Tier")}:
          </dt>
          <dd class="py-1 inline-flex justify-end items-center gap-x-2 text-end">
            <span class="font-medium text-[13px] text-gray-800 dark:text-neutral-200">
              <%= for tag <- get_org_tags(@org) do %>
                <span class="py-1 px-2.5 inline-flex items-center gap-x-1 text-xs rounded-md bg-white border border-gray-200 text-gray-800 dark:bg-neutral-800 dark:border-neutral-700 dark:text-neutral-200">
                  {tag}
                </span>
              <% end %>
            </span>
          </dd>
        </dl>
      </div>
      
    <!-- Card Footer -->
      <div class="py-3 px-4 flex items-center gap-x-3 border-t border-gray-200 dark:border-neutral-700">
        <.link
          navigate={~p"/app/org/#{@org.slug}"}
          class="w-full flex justify-center items-center gap-x-1.5 py-2 px-2.5 border border-transparent bg-teal-600 font-medium text-[13px] text-white hover:bg-teal-700 rounded-md disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-teal-700 dark:border-transparent dark:bg-teal-500 dark:hover:bg-teal-600 dark:focus:bg-teal-600 transition-all duration-200"
        >
          {gettext("View organization")}
          <.icon name="hero-arrow-top-right-on-square" class="w-3.5 h-3.5" />
        </.link>
      </div>
    </div>
    """
  end
end
