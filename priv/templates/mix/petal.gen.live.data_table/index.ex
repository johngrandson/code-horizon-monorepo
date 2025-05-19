defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Live.Index do
  use <%= inspect context.web_module %>, :live_view

  alias <%= inspect context.module %>
  alias <%= inspect schema.module %>

  import <%= inspect context.web_module %>.DataTable
  import <%= inspect context.web_module %>.PageComponents

  @data_table_opts [
    default_limit: 10,
    default_order: %{
      order_by: [:id, :inserted_at],
      order_directions: [:asc, :asc]
    },
    sortable: [:id, :inserted_at, <%= schema.attrs |> Enum.map(fn {k, _v} -> inspect(k) end) |> Enum.join(", ") %>],
    filterable: [:id, :inserted_at, <%= schema.attrs |> Enum.map(fn {k, _v} -> inspect(k) end) |> Enum.join(", ") %>]
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
    |> assign(:page_title, "Edit <%= schema.human_singular %>")
    |> assign(:<%= schema.singular %>, <%= inspect context.alias %>.get_<%= schema.singular %>!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New <%= schema.human_singular %>")
    |> assign(:<%= schema.singular %>, %<%= inspect schema.alias %>{})
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing <%= schema.human_plural %>")
    |> assign_<%= schema.plural %>(params)
    |> assign(index_params: params)
  end

  defp current_index_path(index_params) do
    ~p"<%= schema.route_prefix %>?#{index_params || %{}}"
  end

  @impl true
  def handle_event("update_filters", params, socket) do
    query_params = <%= inspect context.web_module %>.DataTable.build_filter_params(socket.assigns.meta.flop, params)
    {:noreply, push_patch(socket, to: ~p"<%= schema.route_prefix %>?#{query_params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)
    {:ok, _} = <%= inspect context.alias %>.delete_<%= schema.singular %>(<%= schema.singular %>)

    socket =
      socket
      |> assign_<%= schema.plural %>(socket.assigns.index_params)
      |> put_flash(:info, "<%= schema.human_singular %> deleted")

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: current_index_path(socket.assigns.index_params))}
  end

  defp assign_<%= schema.plural %>(socket, params) do
    starting_query = <%= inspect schema.alias %>
    {<%= schema.plural %>, meta} = <%= inspect context.web_module %>.DataTable.search(starting_query, params, @data_table_opts)
    assign(socket, <%= schema.plural %>: <%= schema.plural %>, meta: meta)
  end
end
