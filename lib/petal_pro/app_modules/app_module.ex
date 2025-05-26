defmodule PetalPro.AppModules.AppModule do
  @moduledoc false
  use PetalPro.Schema

  typed_schema "app_modules" do
    field :code, :string
    field :name, :string
    field :description, :string
    field :version, :string
    field :dependencies, {:array, :string}, default: []
    field :status, Ecto.Enum, values: [:active, :inactive, :suspended], default: :inactive
    field :price_id, :string
    field :is_white_label_ready, :boolean, default: false
    field :is_publicly_visible, :boolean, default: false
    field :setup_function, :string
    field :cleanup_function, :string
    field :routes_definition, :map, default: %{}

    timestamps()
  end

  @doc """
  Returns a changeset for the Module model.
  """
  def changeset(module, attrs) do
    # Use `cast` to handle most fields and defaults.
    changeset =
      module
      |> cast(attrs, [
        :code,
        :name,
        :description,
        :version,
        :status,
        :price_id,
        :is_white_label_ready,
        :is_publicly_visible,
        :setup_function,
        :cleanup_function
      ])
      |> validate_required([:code, :name, :version, :status])
      |> unique_constraint(:code)

    # Handle JSONB fields
    changeset
    |> put_jsonb_field_if_present(:dependencies, attrs, :list)
    |> put_jsonb_field_if_present(:routes_definition, attrs, :map)
  end

  # Helper to put JSONB fields in the changeset
  defp put_jsonb_field_if_present(changeset, field_atom, attrs, expected_type) do
    string_key = Atom.to_string(field_atom)

    if Map.has_key?(attrs, string_key) do
      value = Map.get(attrs, string_key)

      case decode_json_value(value, expected_type) do
        {:ok, parsed_value} ->
          put_change(changeset, field_atom, parsed_value)

        {:error, reason} ->
          add_error(changeset, field_atom, reason)
      end
    else
      changeset
    end
  end

  # Helper to decode JSON values
  defp decode_json_value(value, _expected_type) when is_map(value) or is_list(value), do: {:ok, value}
  # Handle nil values
  defp decode_json_value(nil, _expected_type), do: {:ok, nil}

  # Handle JSON strings
  defp decode_json_value(json_string, expected_type) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, parsed} ->
        case {expected_type, parsed} do
          {:map, %{}} -> {:ok, parsed}
          {:list, []} -> {:ok, parsed}
          _ -> {:error, "invalid JSON type, expected #{Atom.to_string(expected_type)}"}
        end

      {:error, _} ->
        {:error, "invalid JSON format"}
    end
  end

  # Handle invalid value types
  defp decode_json_value(_value, _expected_type), do: {:error, "invalid value type for JSON field"}
end
