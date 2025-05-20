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
  def mount(params, _session, socket) do
    index_params = Map.get(params, "index", %{})

    socket =
      assign(socket,
        meta: nil,
        settings: [],
        index_params: index_params,
        page_title: gettext("Global App Settings"),
        setting: nil,
        live_action: nil
      )

    {:ok, socket, temporary_assigns: [settings: []]}
  end

  defp apply_action(socket, :index, _params) do
    index_params = socket.assigns.index_params
    query = Settings.list_settings_query()

    {settings, meta} = DataTable.search(query, index_params, @data_table_opts)

    socket
    |> assign(:settings, settings)
    |> assign(:meta, meta)
    |> assign(:page_title, gettext("Global App Settings"))
    |> assign(:setting, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Setting"))
    |> assign(:setting, Settings.get_setting!(id))
  end

  defp apply_action(socket, :new, _params) do
    setting = %Setting{
      key: "",
      value: "",
      type: "string",
      description: "",
      is_public: false
    }

    socket
    |> assign(:page_title, gettext("New Setting"))
    |> assign(:setting, setting)
    |> assign(:action, :new)
  end

  @impl true
  def handle_info({PetalProWeb.AdminSettingLive.FormComponent, {:saved, setting}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Setting saved successfully"))
      |> push_patch(to: ~p"/admin/settings")
      |> assign(:setting, setting)

    {settings, meta} =
      DataTable.search(
        Settings.list_settings_query(),
        socket.assigns.index_params,
        @data_table_opts
      )

    {:noreply, assign(socket, settings: settings, meta: meta)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    live_action = socket.assigns.live_action || :index

    socket =
      case live_action do
        :index -> apply_action(socket, :index, params)
        :new -> apply_action(socket, :new, params)
        :edit -> apply_action(socket, :edit, params)
        _ -> socket
      end

    {:noreply, assign(socket, live_action: live_action)}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = DataTable.build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: ~p"/admin/settings?#{query_params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    setting = Settings.get_setting!(id)

    case Settings.delete_setting(setting) do
      {:ok, _setting} ->
        {settings, meta} =
          DataTable.search(
            Settings.list_settings_query(),
            socket.assigns.index_params,
            @data_table_opts
          )

        {:noreply,
         socket
         |> assign(settings: settings, meta: meta)
         |> put_flash(:info, gettext("Setting deleted successfully"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete setting"))}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply,
       socket
       |> put_flash(:error, gettext("Setting not found"))
       |> push_patch(to: ~p"/admin/settings")}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/settings")}
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
