defmodule PetalProWeb.AdminOrgLive.Index do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent

  alias PetalPro.Billing.Customers
  alias PetalPro.Orgs
  alias PetalProWeb.DataTable

  @billing_provider Application.compile_env(:petal_pro, :billing_provider)

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
    {:ok,
     assign(socket,
       index_params: nil,
       page_title: gettext("Organizations"),
       billing_provider: @billing_provider
     )}
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
    ~p"/admin/orgs?#{index_params || %{}}"
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

  @impl true
  def handle_event("sync_org_billing", %{"id" => org_id}, socket) do
    with %Customers.Customer{} = customer <- Customers.get_customer_by_source(:org, org_id),
         :ok <- @billing_provider.sync_subscription(customer) do
      socket =
        socket
        |> put_flash(:info, gettext("%{model} billing synced", model: gettext("Organization")))
        |> patch_back_to_index()

      {:noreply, socket}
    else
      _ ->
        {:noreply, put_flash(socket, :info, gettext("No %{model} billing found", model: gettext("Organization")))}
    end
  end

  defp patch_back_to_index(socket) do
    push_patch(socket, to: ~p"/admin/orgs?#{socket.assigns[:index_params] || []}")
  end

  defp assign_orgs(socket, params) do
    starting_query = Orgs.Org
    {orgs, meta} = DataTable.search(starting_query, params, @data_table_opts)
    assign(socket, orgs: orgs, meta: meta)
  end

  defp org_actions(assigns) do
    ~H"""
    <div class="flex items-center" id={"org_actions_container_#{@org.id}"}>
      <.dropdown
        class="dark:shadow-lg"
        options_container_id={"org_options_#{@org.id}"}
        menu_items_wrapper_class="dark:border dark:border-gray-600"
      >
        <.dropdown_menu_item link_type="live_redirect" to={~p"/admin/orgs/#{@org}"}>
          <.icon name="hero-information-circle" class="w-5 h-5" /> {gettext("View")}
        </.dropdown_menu_item>

        <.dropdown_menu_item link_type="live_patch" to={~p"/admin/orgs/#{@org}/edit"}>
          <.icon name="hero-pencil" class="w-5 h-5" /> {gettext("Edit")}
        </.dropdown_menu_item>

        <.dropdown_menu_item
          :if={@billing_provider}
          phx-click={JS.push("sync_org_billing")}
          phx-value-id={@org.id}
          data-confirm={gettext("Are you sure?")}
        >
          <.icon name="hero-arrow-path" class="w-5 h-5" /> {gettext("Sync Billing")}
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
end
