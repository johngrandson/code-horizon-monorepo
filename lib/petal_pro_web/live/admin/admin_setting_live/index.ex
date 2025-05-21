defmodule PetalProWeb.AdminSettingLive.Index do
  @moduledoc """
  A live view to manage global application settings.

  This module provides an interface for administrators to view, create, edit, and delete
  application-wide settings that control various aspects of the system.
  """
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent
  import PetalProWeb.PageComponents

  alias PetalPro.Settings
  alias PetalPro.Settings.Setting
  alias PetalProWeb.DataTable

  require Jason

  @default_setting %Setting{
    key: "",
    value: nil,
    type: "string",
    description: "",
    is_public: false
  }

  @data_table_opts [
    default_limit: 20,
    default_order: %{
      order_by: [:key],
      order_directions: [:asc]
    },
    filterable: [:key, :value, :description],
    sortable: [:key, :inserted_at, :updated_at]
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       index_params: nil,
       page_title: gettext("Global App Settings")
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Setting"))
    |> assign(:setting, Settings.get_setting!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Setting"))
    |> assign(:setting, @default_setting)
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, gettext("Global App Settings"))
    |> assign_settings(params)
    |> assign(:index_params, params)
  end

  defp current_index_path(index_params) do
    ~p"/admin/settings?#{index_params || %{}}"
  end

  @impl true
  def handle_info({PetalProWeb.AdminSettingLive.FormComponent, {:saved, _setting}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Setting saved successfully"))
     |> push_patch(to: current_index_path(socket.assigns.index_params))}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = DataTable.build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: current_index_path(query_params))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    setting = Settings.get_setting!(id)
    {:ok, _} = Settings.delete_setting(setting)

    socket =
      socket
      |> assign_settings(socket.assigns.index_params)
      |> put_flash(:info, gettext("Setting deleted successfully"))

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, patch_back_to_index(socket)}
  end

  defp assign_settings(socket, params) do
    starting_query = Setting
    {settings, meta} = DataTable.search(starting_query, params, @data_table_opts)
    assign(socket, settings: settings, meta: meta)
  end

  defp patch_back_to_index(socket) do
    push_patch(socket, to: ~p"/admin/settings?#{socket.assigns[:index_params] || []}")
  end

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
