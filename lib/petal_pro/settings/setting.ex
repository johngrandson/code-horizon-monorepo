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
    setting
    |> cast(attrs, [:key, :value, :type, :description, :is_public])
    |> validate_required([:key, :value])
    |> validate_inclusion(:type, @setting_types)
    |> validate_inclusion(:is_public, [true, false])
    |> unique_constraint(:key)
  end
end
