defmodule PetalProWeb.AdminSettingLive.FormComponent do
  @moduledoc """
  LiveComponent for handling setting forms in the admin interface.
  Handles creation and editing of settings with different value types.
  """
  use PetalProWeb, :live_component

  alias PetalPro.Settings
  alias PetalPro.Settings.Setting

  @setting_types [
    {"String", "string"},
    {"Number", "number"},
    {"Boolean", "boolean"},
    {"List", "list"}
  ]

  @impl true
  def update(%{setting: setting} = assigns, socket) do
    # Extract the actual value, not the wrapper map
    value =
      cond do
        is_map(setting.value) and is_map_key(setting.value, "value") ->
          setting.value["value"]

        is_nil(setting.value) ->
          ""

        true ->
          setting.value
      end

    # Determine the type based on the value
    value_type = get_setting_type(value)

    # Create a new setting with just the value
    setting_with_value = %{setting | value: value}

    # Create changeset with the proper value
    changeset = Settings.change_setting(setting_with_value)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       setting: setting_with_value,
       current_value: value,
       value_type: value_type,
       setting_types: @setting_types
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"setting" => settings_params}, socket) do
    changeset =
      socket.assigns.setting
      |> Settings.change_setting(settings_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"setting" => params}, socket) do
    params = process_setting_params(params, socket.assigns.value_type, socket)
    save_setting(socket, socket.assigns.action, params)
  end

  @impl true
  def handle_event("change_value_type", %{"setting" => %{"type" => value_type}}, socket) do
    # When changing the value type, reset the current value to a default for the new type
    default_value =
      case value_type do
        "boolean" -> false
        "number" -> 0
        "list" -> []
        "string" -> ""
        _ -> ""
      end

    # Update the form with the new value type and default value
    setting =
      Settings.change_setting(socket.assigns.setting)

    {:noreply,
     socket
     |> assign(:value_type, value_type)
     |> assign(:current_value, default_value)
     |> assign_form(setting)}
  end

  defp process_setting_params(params, value_type, _socket) do
    value_type = params["value_type"] || value_type
    raw_value = get_in(params, ["value"])

    # If raw_value is a map with a "value" key, use that, otherwise use the raw value
    raw_value =
      if is_map(raw_value) and Map.has_key?(raw_value, "value") do
        raw_value["value"]
      else
        raw_value
      end

    # Handle different value types
    case value_type do
      "boolean" ->
        # For booleans, we need to handle both string and boolean values
        boolean_value =
          case raw_value do
            "true" -> true
            "false" -> false
            true -> true
            false -> false
            _ -> false
          end

        Map.merge(params, %{
          "value" => %{"value" => boolean_value},
          "value_type" => value_type
        })

      _ ->
        # For other types, use the existing conversion logic
        case convert_value(raw_value, value_type) do
          {:ok, typed_value} ->
            Map.merge(params, %{
              "value" => %{"value" => typed_value},
              "value_type" => value_type
            })

          {:error, message} ->
            changeset =
              %Setting{value: %{"value" => raw_value}}
              |> Settings.change_setting()
              |> Ecto.Changeset.add_error(:value, "Invalid value: #{message}")

            # Return the changeset directly to be handled by save_setting
            changeset
        end
    end
  end

  defp save_setting(socket, _action, %Ecto.Changeset{} = changeset) do
    {:noreply, assign_form(socket, changeset)}
  end

  defp save_setting(socket, :edit, setting_params) do
    # Ensure we have a proper value structure
    setting_params = ensure_value_structure(setting_params)

    handle_save_result(
      Settings.update_setting(socket.assigns.setting, setting_params),
      gettext("Setting updated successfully"),
      socket
    )
  end

  defp save_setting(socket, :new, setting_params) do
    # Ensure we have a proper value structure
    setting_params = ensure_value_structure(setting_params)

    handle_save_result(
      Settings.create_setting(setting_params),
      gettext("Setting created successfully"),
      socket
    )
  end

  defp ensure_value_structure(params) do
    case params do
      %{"value" => %{"value" => _}} -> params
      %{"value" => value} when is_map(value) -> params
      %{"value" => value} -> Map.put(params, "value", %{"value" => value})
      _ -> Map.put(params, "value", %{"value" => ""})
    end
  end

  defp handle_save_result({:ok, setting}, success_message, socket) do
    {:noreply,
     socket
     |> put_flash(:info, success_message)
     |> push_navigate(to: socket.assigns.return_to)
     |> send_info_to_parent({:saved, setting})}
  end

  defp handle_save_result({:error, %Ecto.Changeset{} = changeset}, _message, socket) do
    {:noreply, assign_form(socket, changeset)}
  end

  # Form handling
  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp send_info_to_parent(socket, info) do
    send(self(), {__MODULE__, info})
    socket
  end

  defp get_setting_type(value) when is_boolean(value), do: "boolean"
  defp get_setting_type(value) when is_number(value), do: "number"
  defp get_setting_type(_), do: "string"

  # Value conversion
  defp convert_value("true", "boolean"), do: {:ok, true}
  defp convert_value("false", "boolean"), do: {:ok, false}
  defp convert_value(true, "boolean"), do: {:ok, true}
  defp convert_value(false, "boolean"), do: {:ok, false}
  defp convert_value(nil, "boolean"), do: {:ok, false}
  defp convert_value(_, "boolean"), do: {:error, "must be true or false"}

  defp convert_value(value, "number") when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> {:ok, float}
      :error -> {:error, "must be a number"}
    end
  end

  defp convert_value(value, "number") when is_number(value), do: {:ok, value}
  defp convert_value(nil, "number"), do: {:ok, 0}
  defp convert_value(_, "number"), do: {:error, "must be a valid number"}

  defp convert_value(nil, _type), do: {:ok, ""}
  defp convert_value(value, _type) when is_binary(value), do: {:ok, String.trim(value)}
  defp convert_value(value, _type), do: {:ok, to_string(value)}
end
