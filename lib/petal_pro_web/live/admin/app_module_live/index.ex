defmodule PetalProWeb.AdminAppModuleLive.Index do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent
  import PetalProWeb.DataTable
  import PetalProWeb.PageComponents

  alias PetalPro.AppModules
  alias PetalPro.AppModules.AppModule

  @data_table_opts [
    default_limit: 10,
    default_order: %{
      order_by: [:id, :inserted_at],
      order_directions: [:asc, :asc]
    },
    sortable: [
      :id,
      :inserted_at,
      :code,
      :name,
      :description,
      :version,
      :dependencies,
      :status,
      :price_id,
      :is_white_label_ready,
      :is_publicly_visible,
      :setup_function,
      :cleanup_function,
      :routes_definition
    ],
    filterable: [
      :id,
      :inserted_at,
      :code,
      :name,
      :description,
      :version,
      :dependencies,
      :status,
      :price_id,
      :is_white_label_ready,
      :is_publicly_visible,
      :setup_function,
      :cleanup_function,
      :routes_definition
    ]
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, index_params: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit App module")
    |> assign(:app_module, AppModules.get_app_module!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New App module")
    |> assign(:app_module, %AppModule{})
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing App modules")
    |> assign_app_modules(params)
    |> assign(index_params: params)
  end

  defp current_index_path(index_params) do
    ~p"/admin/app-modules?#{index_params || %{}}"
  end

  @impl true
  def handle_event("update_filters", params, socket) do
    query_params = PetalProWeb.DataTable.build_filter_params(socket.assigns.meta.flop, params)
    {:noreply, push_patch(socket, to: ~p"/admin/app-modules?#{query_params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    app_module = AppModules.get_app_module!(id)
    {:ok, _} = AppModules.delete_app_module(app_module)

    socket =
      socket
      |> assign_app_modules(socket.assigns.index_params)
      |> put_flash(:info, "App module deleted")

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: current_index_path(socket.assigns.index_params))}
  end

  defp assign_app_modules(socket, params) do
    starting_query = AppModule
    {app_modules, meta} = PetalProWeb.DataTable.search(starting_query, params, @data_table_opts)
    assign(socket, app_modules: app_modules, meta: meta)
  end
end
