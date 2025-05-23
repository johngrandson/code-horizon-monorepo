defmodule PetalProWeb.OrgsLive do
  @moduledoc """
  List all orgs for the current_user with improved styling and user experience.
  """
  use PetalProWeb, :live_view

  alias PetalPro.Orgs
  alias PetalPro.Orgs.Membership
  alias PetalPro.Orgs.Org

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:invitations, Orgs.list_invitations_by_user(socket.assigns.current_user))
      |> assign(:orgs, Orgs.list_orgs(socket.assigns.current_user))
      |> assign(:is_org_admin, Membership.is_admin_from_current_org(socket.assigns.current_user))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/orgs")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout current_page={:orgs} current_user={@current_user} type="sidebar">
      <.container class="py-4">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
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
            <.alert
              with_icon
              class="max-w-md mb-8 shadow-sm border-l-4 border-amber-500"
              color="warning"
              heading={gettext("New invitations")}
            >
              <div class="mb-2">
                {gettext("You have %{count} pending invitation(s) waiting for your response.",
                  count: length(@invitations)
                )}
              </div>

              <.button
                link_type="live_redirect"
                color="success"
                to={~p"/app/users/org-invitations"}
                class="transition-all hover:translate-x-1"
              >
                {gettext("View invitations")}
                <.icon name="hero-arrow-right" class="w-4 h-4 ml-2" />
              </.button>
            </.alert>
          <% end %>

          <div class="flex items-center justify-end m-2">
            <div class="text-sm text-gray-500 dark:text-gray-400">
              <%= if @orgs != [] do %>
                <span class="font-medium">{length(@orgs)}</span> {gettext("organizations")}
              <% end %>
            </div>
          </div>

          <%= if Enum.all?([@orgs, @invitations], &Enum.empty?/1) do %>
            <div class="bg-white dark:bg-neutral-900 rounded-xl shadow-sm border border-gray-200 dark:border-neutral-700 p-8 mb-8">
              <div class="text-center">
                <.icon
                  name="hero-building-office-2"
                  class="w-16 h-16 mx-auto text-gray-400 dark:text-neutral-500"
                />

                <h3 class="mt-4 text-lg font-medium text-gray-900 dark:text-white">
                  {gettext("No organizations yet")}
                </h3>

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
            <div class="gap-6 mb-8">
              <%= if @orgs != [] do %>
                <%= for org <- @orgs do %>
                  <.link
                    navigate={~p"/app/org/#{org.slug}"}
                    class="block p-4 mb-4 bg-white border border-gray-200 rounded-xl hover:border-gray-300 transition-all dark:bg-neutral-800 dark:border-neutral-700 dark:hover:border-neutral-600 focus:outline-none focus:ring-2 focus:ring-primary-500"
                  >
                    <div class="relative sm:flex sm:justify-between sm:gap-x-4">
                      <div>
                        <div class="flex items-center gap-x-4">
                          <div class="relative shrink-0">
                            <img
                              class="shrink-0 size-9.5 sm:w-11.5 sm:h-11.5 rounded-full object-cover"
                              src={org.avatar_url}
                              alt={org.name}
                            />
                            <%= if org.is_enterprise do %>
                              <.pro_badge />
                            <% end %>
                          </div>

                          <div class="grow flex flex-col">
                            <div class="inline-flex items-center gap-x-2">
                              <h3 class="font-medium text-gray-800 dark:text-neutral-200">
                                {org.name}
                              </h3>
                              <span class="inline-flex items-center gap-x-1.5 py-1 px-2.5 text-xs font-medium bg-primary-100 text-primary-800 rounded-full dark:bg-primary-900 dark:text-primary-300">
                                {org.plan}
                              </span>
                            </div>

                            <div class="inline-flex items-center gap-x-2">
                              <svg
                                class="shrink-0 size-3 sm:size-3.5 text-gray-500 dark:text-neutral-500"
                                xmlns="http://www.w3.org/2000/svg"
                                width="24"
                                height="24"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                              >
                                <path d="M15 7h3a5 5 0 0 1 5 5 5 5 0 0 1-5 5h-3m-6 0H6a5 5 0 0 1-5-5 5 5 0 0 1 5-5h3" />
                                <line x1="8" y1="12" x2="16" y2="12" />
                              </svg>
                              <p
                                class="text-xs sm:text-sm text-gray-500 dark:text-neutral-500"
                                title={org.slug}
                              >
                                {org.slug}
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div class="mt-2 sm:mt-0">
                        <div class="flex justify-end items-center gap-x-4">
                          <div class="whitespace-nowrap">
                            <p class="text-xs sm:text-sm text-gray-500 dark:text-neutral-500">
                              <.icon name="hero-users" class="w-3.5 h-3.5 inline mr-1" />
                              {org.max_users} {gettext("users")}
                            </p>
                          </div>

                          <div class="py-2 px-3 flex items-center justify-center sm:justify-start text-primary-600 dark:text-primary-400">
                            <span class="text-xs font-medium">{gettext("View organization")}</span>
                            <.icon
                              name="hero-arrow-right"
                              class="w-4 h-4 ml-1 transition-transform group-hover:translate-x-1"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </.link>
                <% end %>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </.container>

      <%= if @live_action == :new do %>
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
