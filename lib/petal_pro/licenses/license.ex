defmodule PetalPro.Licenses.License do
  @moduledoc """
  Schema representing a software license in the system.

  Licenses control access to features and resources for orgs.
  """
  use PetalPro.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias PetalPro.Licenses.Quota
  alias PetalPro.Licenses.UsageRecord
  alias PetalPro.Orgs.Org

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @type_enum ["subscription", "perpetual", "trial"]
  @status_enum ["active", "expired", "revoked"]

  typed_schema "licenses" do
    field :key, :string
    field :type, :string
    field :status, :string, default: "active"
    field :starts_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :max_users, :integer
    field :max_storage_mb, :integer
    field :features, :map, default: %{}
    field :metadata, :map, default: %{}

    belongs_to :org, Org

    has_many :usage_quotas, Quota
    has_many :usage_records, UsageRecord

    timestamps()
  end

  @doc """
  Creates a changeset for a new license.
  """
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :key,
      :type,
      :status,
      :starts_at,
      :expires_at,
      :max_users,
      :max_storage_mb,
      :features,
      :metadata,
      :org_id
    ])
    |> validate_required([:key, :type, :org_id])
    |> validate_inclusion(:type, @type_enum)
    |> validate_inclusion(:status, @status_enum)
    |> validate_number(:max_users, greater_than_or_equal_to: 0)
    |> validate_number(:max_storage_mb, greater_than_or_equal_to: 0)
    |> unique_constraint(:key, name: :licenses_key_index)
    |> foreign_key_constraint(:org_id)
  end

  @doc """
  Updates an existing license.
  """
  def update_changeset(license, attrs) do
    license
    |> cast(attrs, [
      :type,
      :status,
      :starts_at,
      :expires_at,
      :max_users,
      :max_storage_mb,
      :features,
      :metadata
    ])
    |> validate_inclusion(:type, @type_enum)
    |> validate_inclusion(:status, @status_enum)
    |> validate_number(:max_users, greater_than_or_equal_to: 0)
    |> validate_number(:max_storage_mb, greater_than_or_equal_to: 0)
  end

  @doc """
  Checks if the license is currently active.
  """
  def active?(%__MODULE__{status: "active"} = license) do
    now = DateTime.utc_now()

    cond do
      is_nil(license.starts_at) and is_nil(license.expires_at) ->
        true

      is_nil(license.starts_at) ->
        DateTime.compare(now, license.expires_at) in [:lt, :eq]

      is_nil(license.expires_at) ->
        DateTime.compare(now, license.starts_at) in [:gt, :eq]

      true ->
        DateTime.compare(now, license.starts_at) in [:gt, :eq] and
          DateTime.compare(now, license.expires_at) in [:lt, :eq]
    end
  end

  def active?(_), do: false

  @doc """
  Returns the remaining days until the license expires.
  Returns nil if there's no expiration date.
  """
  def days_until_expiration(%__MODULE__{expires_at: nil}), do: nil

  def days_until_expiration(license) do
    now = DateTime.utc_now()

    case DateTime.compare(now, license.expires_at) do
      # Already expired
      :gt ->
        0

      _ ->
        diff_in_seconds = DateTime.diff(license.expires_at, now, :second)
        # Round up to full days
        max(0, div(diff_in_seconds, 86_400) + 1)
    end
  end
end
