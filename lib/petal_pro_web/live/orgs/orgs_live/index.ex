defmodule PetalProWeb.OrgsLive.Index do
  @moduledoc """
  List all orgs for the current_user with improved styling and user experience.
  """
  use PetalProWeb, :live_view

  import PetalPro.Events.Modules.Orgs.Subscriber
  import PetalProWeb.Components.OrgCard

  alias PetalPro.Orgs
  alias PetalProWeb.DataTable

  require Logger

  @data_table_opts [
    default_limit: 9,
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    },
    sortable: [:id, :slug, :name, :inserted_at],
    filterable: [:id, :slug, :name]
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(index_params: nil)
      |> assign(base_url_params: %{})
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
    |> assign(:page_title, "New Organization")
    |> assign(:org, %Orgs.Org{})
  end

  defp apply_action(socket, :index, params) do
    base_params = extract_base_params(params)

    socket
    |> assign(:page_title, gettext("Organizations"))
    |> assign_orgs(params)
    |> assign(index_params: params)
    |> assign(base_url_params: base_params)
  end

  defp extract_base_params(params) do
    Map.drop(params, ["page", "page_size", "filters", "order_by", "order_directions"])
  end

  defp current_index_path(socket) when is_map(socket) do
    meta = socket.assigns[:meta]

    if meta do
      current_params = build_current_params(meta)
      ~p"/app/orgs?#{current_params}"
    else
      ~p"/app/orgs"
    end
  end

  defp current_index_path(index_params) when is_map(index_params) do
    ~p"/app/orgs?#{index_params}"
  end

  defp current_index_path(nil) do
    ~p"/app/orgs"
  end

  defp build_current_params(meta) do
    DataTable.build_params_from_meta(meta)
  end

  @impl true
  def handle_info({:invitation_sent, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket = assign_invitations(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:invitation_deleted, %{invitation_id: _invitation_id, org_id: _org_id}}, socket) do
    socket = assign_invitations(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = DataTable.build_filter_params(socket.assigns.meta, socket.assigns.base_url_params, filter_params)
    {:noreply, push_patch(socket, to: ~p"/app/orgs?#{query_params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org = Orgs.get_org_by_id!(id)
    {:ok, _} = Orgs.delete_org(org)

    socket = handle_post_delete_pagination(socket)

    socket =
      put_flash(socket, :info, gettext("%{model} successfully deleted", model: gettext("Organization")))

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, patch_back_to_index(socket)}
  end

  defp handle_post_delete_pagination(socket) do
    current_meta = socket.assigns.meta
    current_params = build_current_params(current_meta)

    socket = assign_orgs(socket, current_params)
    new_meta = socket.assigns.meta

    # Check if we need to adjust pagination
    cond do
      # If we deleted the last item on the current page and we're not on page 1
      new_meta.total_count > 0 &&
        length(socket.assigns.orgs) == 0 &&
          current_meta.current_page > 1 ->
        # Go to previous page
        adjusted_params = Map.put(current_params, "page", current_meta.current_page - 1)
        assign_orgs(socket, adjusted_params)

      # If we have no items left and we were filtering, stay where we are
      new_meta.total_count == 0 ->
        socket

      # Otherwise, stay on current page
      true ->
        socket
    end
  end

  defp assign_invitations(socket) do
    assign(socket, :invitations, Orgs.list_invitations_by_user(socket.assigns.current_user))
  end

  defp assign_orgs(socket, params) do
    starting_query = Orgs.Org.by_user(socket.assigns.current_user)

    {orgs, meta} = DataTable.search(starting_query, params, @data_table_opts)

    socket
    |> assign(orgs: orgs, meta: meta)
    |> update_index_params(params)
  end

  defp update_index_params(socket, params) do
    assign(socket, index_params: params)
  end

  defp patch_back_to_index(socket) do
    cond do
      # If we have meta, use it to preserve current state
      socket.assigns[:meta] ->
        path = current_index_path(socket)
        push_patch(socket, to: path)

      # If we have index_params, use them
      socket.assigns[:index_params] ->
        path = current_index_path(socket.assigns.index_params)
        push_patch(socket, to: path)

      # Fallback to base path
      true ->
        push_patch(socket, to: ~p"/app/orgs")
    end
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
    <div class="flex flex-col md:flex-row md:items-center md:justify-between">
      <.page_header
        title={gettext("Organizations")}
        description={gettext("Manage your organizations")}
      />
      <%= if @current_user.confirmed_at do %>
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

  defp render_organizations(assigns) do
    ~H"""
    <div class="pt-2 md:pt-4 pb-10">
      <.data_cards
        meta={@meta}
        items={@orgs}
        grid_cols="grid-cols-1 md:grid-cols-3 xl:grid-cols-3 2xl:grid-cols-4"
        base_url_params={@base_url_params}
        class="space-y-6"
      >
        <!-- Filter Slot -->
        <:filter :let={form}>
          <div class="bg-white dark:bg-neutral-800 p-4 rounded-lg border border-gray-200 dark:border-neutral-700">
            <h3 class="text-sm font-medium text-gray-900 dark:text-white mb-3">
              {gettext("Filters")}
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <.input
                  field={form[:name]}
                  type="text"
                  placeholder={gettext("Search by name...")}
                  label={gettext("Organization Name")}
                />
              </div>
              <div>
                <.input
                  field={form[:status]}
                  type="select"
                  options={[
                    {gettext("All"), ""},
                    {gettext("Active"), "active"},
                    {gettext("Inactive"), "inactive"}
                  ]}
                  label={gettext("Status")}
                />
              </div>
              <div>
                <.input
                  field={form[:role]}
                  type="select"
                  options={[
                    {gettext("All Roles"), ""},
                    {gettext("Admin"), "admin"},
                    {gettext("Member"), "member"}
                  ]}
                  label={gettext("My Role")}
                />
              </div>
            </div>
          </div>
        </:filter>

        <:card :let={org}>
          <!-- Card Slot - Using the separate OrgCard component -->
          <.org_card org={org} current_user={@current_user} socket={@socket} />
        </:card>

        <:if_empty>
          <!-- Empty State Slot -->
          <div class="text-center py-16">
            <div class="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-blue-100 to-purple-100 dark:from-blue-900/30 dark:to-purple-900/30 rounded-3xl flex items-center justify-center">
              <.icon name="hero-building-office-2" class="w-12 h-12 text-blue-600 dark:text-blue-400" />
            </div>
            <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-3">
              {gettext("No organizations yet")}
            </h3>
            <p class="text-gray-500 dark:text-neutral-400 max-w-md mx-auto mb-6">
              {gettext(
                "Create your first organization to start collaborating with your team and managing projects."
              )}
            </p>
            <.link
              navigate={~p"/app/orgs/new"}
              class="inline-flex items-center gap-2 rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-700"
            >
              <.icon name="hero-plus" class="w-4 h-4" />
              {gettext("Create Organization")}
            </.link>
          </div>
        </:if_empty>
      </.data_cards>

      <%= if length(@orgs) > 0 do %>
        <div class="mt-5">
          <div class="grid grid-cols-2 items-center gap-y-2 sm:gap-y-0 sm:gap-x-5">
            <p class="text-sm text-gray-800 dark:text-neutral-200">
              <span class="font-medium">{@meta.total_count}</span>
              <span class="text-gray-500 dark:text-neutral-500">
                {ngettext("organization", "organizations", @meta.total_count)}
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
end
