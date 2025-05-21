defmodule PetalProWeb.AdminSettingLive.Show do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.PageComponents

  alias PetalPro.Settings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:setting, Settings.get_setting!(id))}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/settings/#{socket.assigns.setting}")}
  end

  defp page_title(:show), do: gettext("Show Setting")
  defp page_title(:edit), do: gettext("Edit Setting")

  # Formats a setting value for display in the UI.
  # Handles different types of values including maps, lists, and other basic types.
  defp format_setting_value(value) when is_map(value) do
    case value do
      %{"value" => v} -> format_setting_value(v)
      _ -> Jason.encode!(value, pretty: true)
    end
  end

  defp format_setting_value(value) when is_list(value) do
    Jason.encode!(value, pretty: true)
  end

  defp format_setting_value(value) when is_binary(value) do
    value
  end

  defp format_setting_value(value) when is_number(value) do
    to_string(value)
  end

  defp format_setting_value(value) when is_boolean(value) do
    if value, do: "true", else: "false"
  end

  defp format_setting_value(value) when is_nil(value) do
    ""
  end

  defp format_setting_value(value) do
    inspect(value)
  end
end
