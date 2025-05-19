defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Live.Show do
  use <%= inspect context.web_module %>, :live_view

  alias <%= inspect context.module %>

  import <%= inspect context.web_module %>.PageComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:<%= schema.singular %>, <%= inspect context.alias %>.get_<%= schema.singular %>!(id))}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"<%= schema.route_prefix %>/#{socket.assigns.<%= schema.singular %>}")}
  end

  defp page_title(:show), do: "Show <%= schema.human_singular %>"
  defp page_title(:edit), do: "Edit <%= schema.human_singular %>"
end
