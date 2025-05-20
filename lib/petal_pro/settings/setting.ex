defmodule PetalPro.Settings.Setting do
  @moduledoc """
  Schema for storing application settings with support for various value types.
  """
  use PetalPro.Schema

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @setting_types ["string", "boolean", "number", "map", "list"]

  typed_schema "settings" do
    field :key, :string
    field :value, :map
    field :type, :string, default: "string"
    field :description, :string
    field :is_public, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for a setting.
  """
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(setting, attrs) do
    attrs = normalize_value_for_storage(attrs)

    setting
    |> cast(attrs, [:key, :value, :type, :description, :is_public])
    |> validate_required([:key, :value])
    |> validate_inclusion(:type, @setting_types)
    |> validate_inclusion(:is_public, [true, false])
    |> unique_constraint(:key)
  end

  @doc """
  Normalize value for database storage.

  Converts primitive values to map format for storage while
  preserving the actual type information.
  """
  def normalize_value_for_storage(%{"value" => value} = attrs) do
    # Determine value type
    type = determine_value_type(value)

    # Update attrs with proper value and type
    Map.put(attrs, "type", type)
  end

  def normalize_value_for_storage(attrs), do: attrs

  # Determine the type of a value.
  defp determine_value_type(value) when is_boolean(value), do: "boolean"
  defp determine_value_type(value) when is_integer(value), do: "number"
  defp determine_value_type(value) when is_float(value), do: "number"
  defp determine_value_type(value) when is_map(value), do: "map"
  defp determine_value_type(value) when is_list(value), do: "list"
  defp determine_value_type(_), do: "string"
end
