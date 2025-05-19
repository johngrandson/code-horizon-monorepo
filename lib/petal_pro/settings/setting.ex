defmodule PetalPro.Settings.Setting do
  @moduledoc """
  Schema for storing application settings.
  """
  use PetalPro.Schema

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id
  typed_schema "settings" do
    field :key, :string
    field :value, :map
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
    |> cast(attrs, [:key, :value, :description, :is_public])
    |> validate_required([:key, :value])
    |> validate_inclusion(:is_public, [true, false])
    |> unique_constraint(:key)
  end

  @doc """
  Creates a changeset for a new setting.
  """
  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  @doc """
  Updates a setting with the given attributes.
  """
  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(setting, attrs) do
    changeset(setting, attrs)
  end
end
