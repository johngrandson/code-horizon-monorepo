defmodule PetalProWeb.AdminAppModuleLive.Show do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent
  import PetalProWeb.PageComponents

  alias PetalPro.AppModules

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:app_module, AppModules.get_app_module!(id))}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/app-modules/#{socket.assigns.app_module}")}
  end

  defp page_title(:show), do: "Show App module"
  defp page_title(:edit), do: "Edit App module"
end
