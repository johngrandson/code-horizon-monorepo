# lib/petal_pro/modules/module.ex
defmodule PetalPro.Modules.Module do
  @moduledoc false
  use PetalPro.Schema

  typed_schema "modules" do
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

    # Depois, lide com os campos JSONB separadamente, se eles foram passados nos `attrs`.
    # Isso é importante para converter strings JSON (de formulários, por exemplo) para os tipos corretos.
    # Se os campos não estiverem em `attrs` ou forem `nil`, o `cast` inicial já aplicou os defaults do schema.
    changeset
    |> put_jsonb_field_if_present(:dependencies, attrs, :list)
    |> put_jsonb_field_if_present(:routes_definition, attrs, :map)
  end

  # Helper para processar campos JSONB: decodifica se for string, caso contrário, usa o valor.
  # Adiciona ao changeset se o campo estiver presente nos `attrs`.
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
      # Campo não presente nos `attrs`, o `cast` inicial já lida com o default
      changeset
    end
  end

  # Helper para decodificar valores JSON
  defp decode_json_value(value, _expected_type) when is_map(value) or is_list(value), do: {:ok, value}
  # Permite nil, se o campo for opcional
  defp decode_json_value(nil, _expected_type), do: {:ok, nil}

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

  defp decode_json_value(_value, _expected_type), do: {:error, "invalid value type for JSON field"}
end
