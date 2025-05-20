defmodule PetalProWeb.AdminSettingLive.FormComponent do
  @moduledoc """
  LiveComponent for handling setting forms in the admin interface.
  """
  use PetalProWeb, :live_component

  alias PetalPro.Settings
  alias PetalPro.Settings.Setting

  @setting_types [
    {"String", "string"},
    {"Number", "number"},
    {"Boolean", "boolean"},
    {"Map", "map"},
    {"List", "list"}
  ]

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{setting: setting} = assigns, socket) do
    # Initialize with a blank changeset
    changeset = Setting.changeset(setting, %{})

    # Get initial type and value
    type = setting.type || "string"
    value = extract_value(setting.value)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       setting: setting,
       type: type,
       value: format_value_for_display(value, type),
       setting_types: @setting_types
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Extract form data
    form_data = params["setting"] || %{}

    # Check if type has changed
    current_type = socket.assigns.type
    new_type = form_data["type"] || current_type

    # Get value from form
    value = form_data["value"]

    # Handle type change
    socket =
      if new_type != current_type do
        # Format value for the new type
        formatted_value = format_value_for_display(convert_value(value, current_type, new_type), new_type)
        assign(socket, type: new_type, value: formatted_value)
      else
        # Just update the value
        assign(socket, value: value)
      end

    # Don't validate yet, just update form
    changeset = Setting.changeset(socket.assigns.setting, %{})

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"setting" => form_data}, socket) do
    # Prepare final data for saving
    type = form_data["type"] || socket.assigns.type

    # Process value based on type
    processed_value = process_value_for_save(form_data["value"], type)

    # Final params for saving
    params = %{
      "key" => form_data["key"],
      "type" => type,
      "value" => processed_value,
      "description" => form_data["description"],
      "is_public" => form_data["is_public"] == "true"
    }

    # Save to database
    save_result =
      case socket.assigns.action do
        :edit -> Settings.update_setting(socket.assigns.setting, params)
        :new -> Settings.create_setting(params)
      end

    case save_result do
      {:ok, setting} ->
        # Send message to parent to avoid redirect
        send(self(), {:saved_setting, setting})
        {:noreply, put_flash(socket, :info, "Setting saved successfully")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # --- Helper functions ---

  # Extract raw value from various formats
  defp extract_value(value) do
    cond do
      is_map(value) && Map.has_key?(value, "value") -> value["value"]
      is_nil(value) -> ""
      true -> value
    end
  end

  # Format value for display based on type
  defp format_value_for_display(value, "boolean") when is_boolean(value), do: value
  defp format_value_for_display(value, "boolean") when value in ["true", true], do: true
  defp format_value_for_display(_, "boolean"), do: false

  defp format_value_for_display(value, "map") when is_map(value) do
    Jason.encode!(value, pretty: true)
  rescue
    _ -> "{}"
  end

  defp format_value_for_display(value, "list") when is_list(value) do
    Jason.encode!(value, pretty: true)
  rescue
    _ -> "[]"
  end

  defp format_value_for_display(value, "number") when is_number(value), do: value

  defp format_value_for_display(value, "number") when is_binary(value) do
    case Float.parse(value) do
      {num, _} -> num
      :error -> 0
    end
  end

  defp format_value_for_display(_, "number"), do: 0

  defp format_value_for_display(value, "string") when is_binary(value), do: value
  defp format_value_for_display(value, "string"), do: to_string(value)
  defp format_value_for_display(value, _), do: value

  # Convert value when changing types
  defp convert_value(value, from_type, to_type) do
    # First normalize to raw value
    raw_value =
      case from_type do
        "boolean" when value in ["true", true] ->
          true

        "boolean" ->
          false

        "number" when is_binary(value) ->
          case Float.parse(value) do
            {num, _} -> num
            :error -> 0
          end

        "map" when is_binary(value) ->
          case Jason.decode(value) do
            {:ok, decoded} -> decoded
            _ -> %{}
          end

        "list" when is_binary(value) ->
          case Jason.decode(value) do
            {:ok, decoded} when is_list(decoded) -> decoded
            _ -> []
          end

        _ ->
          value
      end

    # Then convert to target type
    case to_type do
      "boolean" -> !!raw_value
      "number" when is_number(raw_value) -> raw_value
      "number" -> 0
      "map" when is_map(raw_value) -> raw_value
      "map" -> %{}
      "list" when is_list(raw_value) -> raw_value
      "list" -> []
      "string" -> to_string(raw_value)
      _ -> raw_value
    end
  end

  # Process value for saving to database
  defp process_value_for_save(value, "boolean") when value in ["true", true], do: true
  defp process_value_for_save(_, "boolean"), do: false

  defp process_value_for_save(value, "number") when is_number(value), do: value

  defp process_value_for_save(value, "number") when is_binary(value) do
    case Float.parse(value) do
      {num, _} -> num
      :error -> 0
    end
  end

  defp process_value_for_save(_, "number"), do: 0

  defp process_value_for_save(value, "map") when is_map(value), do: value

  defp process_value_for_save(value, "map") when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} -> decoded
      _ -> %{}
    end
  end

  defp process_value_for_save(_, "map"), do: %{}

  defp process_value_for_save(value, "list") when is_list(value), do: value

  defp process_value_for_save(value, "list") when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} when is_list(decoded) -> decoded
      _ -> []
    end
  end

  defp process_value_for_save(_, "list"), do: []

  defp process_value_for_save(value, "string") when is_binary(value), do: String.trim(value)
  defp process_value_for_save(value, "string"), do: to_string(value)

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
