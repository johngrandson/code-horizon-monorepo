defmodule PetalProWeb.OrgsLive do
  @moduledoc """
  List all orgs for the current_user with improved styling and user experience.
  """
  use PetalProWeb, :live_view

  import PetalPro.Events.Modules.Orgs.Subscriber
  import PetalProWeb.Components.ActionDropdown

  alias PetalPro.Orgs
  alias PetalPro.Orgs.Membership
  alias PetalPro.Orgs.Org

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    is_org_admin = Membership.is_org_admin?(socket.assigns.current_user)

    socket =
      socket
      |> assign_invitations()
      |> assign_orgs()
      |> assign(:is_org_admin, is_org_admin)
      |> register_subscriber()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:invitation_sent, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket =
      socket
      |> assign_invitations()
      |> assign_orgs()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:invitation_deleted, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket =
      socket
      |> assign_invitations()
      |> assign_orgs()

    {:noreply, socket}
  end

  @impl true
  def handle_event("dropdown_action", %{"action" => action, "id" => id}, socket) do
    org = Orgs.get_org_by_id(id)

    if org do
      handle_org_action(action, org, socket)
    else
      socket = put_flash(socket, :error, "Organization not found")
      {:noreply, socket}
    end
  end

  defp handle_org_action(action, org, socket) do
    socket =
      case action do
        "edit_org" ->
          push_patch(socket, to: ~p"/app/org/#{org.slug}/edit")

        "delete" ->
          case Orgs.delete_org(org) do
            {:ok, _org} ->
              socket
              |> put_flash(:info, "Organization deleted successfully")
              |> push_navigate(to: ~p"/app/orgs")

            {:error, _changeset} ->
              put_flash(socket, :error, "Failed to delete organization")
          end

        _ ->
          socket
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New organization"))
    |> assign(:org, %Org{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Organizations"))
    |> assign(:org, nil)
  end

  defp assign_invitations(socket) do
    assign(socket, :invitations, Orgs.list_invitations_by_user(socket.assigns.current_user))
  end

  defp assign_orgs(socket) do
    assign(socket, :orgs, Orgs.list_orgs(socket.assigns.current_user))
  end

  defp get_org_tags(org) do
    if org.is_enterprise, do: ["Enterprise"], else: ["Regular"]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout current_page={:orgs} current_user={@current_user} type="sidebar">
      <.container class="py-4">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between">
          <.page_header
            title={gettext("Organizations")}
            description={gettext("Manage your organizations")}
          />
          <%= if @current_user.confirmed_at do %>
            <.button
              :if={@is_org_admin}
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

        <%= if @current_user.confirmed_at do %>
          <%= if @invitations != [] do %>
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
          <% end %>

          <%= if Enum.all?([@orgs], &Enum.empty?/1) do %>
            <div class="bg-white dark:bg-neutral-900 rounded-xl shadow-sm border border-gray-200 dark:bg-neutral-900 dark:border-neutral-700 p-8 mb-8">
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

                <.button
                  :if={@is_org_admin}
                  link_type="live_redirect"
                  color="primary"
                  size="lg"
                  to={~p"/app/orgs/new"}
                  class="mt-6 transition-all hover:scale-105"
                >
                  <.icon name="hero-plus" class="w-5 h-5 mr-2" />
                  {gettext("Create your first organization")}
                </.button>
              </div>
            </div>
          <% else %>
            <!-- Enhanced Grid Layout for Organization Cards -->
            <div class="pt-2 md:pt-4 pb-10">
              <div class="w-full max-w-5xl mx-auto">
                <!-- Grid -->
                <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 xl:gap-6">
                  <%= for org <- @orgs do %>
                    <!-- Enhanced Organization Card -->
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
                          <g clip-path="url(#clip0_org_#{org.id})">
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
                            <clipPath id={"clip0_org_#{org.id}"}>
                              <rect width="576" height="120" fill="white" />
                            </clipPath>
                          </defs>
                        </svg>
                      </figure>
                      
    <!-- Avatar Section -->
                      <div class="-mt-8 px-4 mb-3">
                        <div class="relative flex items-center gap-x-3">
                          <div class="relative w-20">
                            <%= if org.avatar_url do %>
                              <img
                                class="shrink-0 size-20 ring-4 ring-white rounded-3xl dark:ring-neutral-800 object-cover"
                                src={org.avatar_url}
                                alt={org.name}
                              />
                            <% else %>
                              <div class="shrink-0 size-20 ring-4 ring-white rounded-3xl dark:ring-neutral-800 bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                                <span class="text-white font-bold text-5xl">
                                  {String.first(org.name)}
                                </span>
                              </div>
                            <% end %>

                            <%= if org.is_enterprise do %>
                              <div class="absolute -bottom-3 inset-x-0 text-center">
                                <span class="py-1 px-2 inline-flex items-center gap-x-1 text-xs font-semibold uppercase rounded-md bg-gradient-to-tr from-lime-500 to-teal-500 text-white">
                                  Pro
                                </span>
                              </div>
                            <% end %>
                          </div>
                          
    <!-- Action Buttons -->
                          <div class="absolute bottom-2 end-0">
                            <div class="h-full flex justify-end items-end gap-x-2">
                              <!-- Favorite Button -->
                              <button
                                type="button"
                                phx-click="toggle_favorite"
                                phx-value-org_id={org.id}
                                class="hs-tooltip flex justify-center items-center gap-x-3 size-8 text-sm border border-gray-200 text-gray-600 hover:bg-gray-100 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:border-neutral-700 dark:text-neutral-400 dark:hover:bg-neutral-700 dark:focus:bg-neutral-700 dark:hover:text-neutral-200 dark:focus:text-neutral-200 transition-all duration-200"
                              >
                                <.icon name="hero-star" class="w-3.5 h-3.5" />
                                <span class="sr-only">Add to favorites</span>
                              </button>

                              <div class="hover:pointer-events-auto">
                                <.action_dropdown
                                  id={"org-#{org.id}"}
                                  entity_id={org.id}
                                  entity_type={:org}
                                  can_edit?={Orgs.can_edit_org?(:edit, @current_user)}
                                  can_delete?={Orgs.can_delete_org?(:delete, @current_user)}
                                  edit_url={~p"/app/org/#{org.slug}/edit"}
                                />
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                      
    <!-- Card Body -->
                      <div class="p-4 h-full">
                        <h2 class="mb-2 font-medium text-gray-800 dark:text-neutral-300 truncate">
                          {org.name}
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
                            {org.slug}
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
                              <%= for tag <- get_org_tags(org) do %>
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
                          navigate={~p"/app/org/#{org.slug}"}
                          class="w-full flex justify-center items-center gap-x-1.5 py-2 px-2.5 border border-transparent bg-teal-600 font-medium text-[13px] text-white hover:bg-teal-700 rounded-md disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-teal-700 dark:border-transparent dark:bg-teal-500 dark:hover:bg-teal-600 dark:focus:bg-teal-600 transition-all duration-200"
                        >
                          {gettext("View organization")}
                          <.icon name="hero-arrow-top-right-on-square" class="w-3.5 h-3.5" />
                        </.link>
                      </div>
                    </div>
                    <!-- End Enhanced Organization Card -->
                  <% end %>
                </div>
                <!-- End Grid -->

                <!-- Pagination Footer (if needed) -->
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
            </div>
          <% end %>
        <% end %>
      </.container>

      <%= if @live_action in [:new] do %>
        <.modal max_width="lg" title={@page_title}>
          <.live_component
            module={PetalProWeb.OrgFormComponent}
            id={:new}
            action={@live_action}
            org={@org}
            return_to={~p"/app/orgs"}
            current_user={@current_user}
          />
        </.modal>
      <% end %>
    </.layout>
    """
  end
end
