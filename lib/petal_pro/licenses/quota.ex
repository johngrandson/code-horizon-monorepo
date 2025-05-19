defmodule PetalPro.Licenses.Quota do
  @moduledoc """
  Schema representing a usage quota for a specific feature in the system.

  Tracks usage limits and current usage for various features like storage, users, etc.
  """
  use PetalPro.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias PetalPro.Licenses.License
  alias PetalPro.Orgs.Org

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @reset_periods ["monthly", "yearly", "never"]
  @features ["storage_mb", "active_users", "api_calls"]

  typed_schema "usage_quotas" do
    field :feature, :string
    field :limit, :integer
    field :current_usage, :integer, default: 0
    field :reset_period, :string
    field :reset_at, :utc_datetime

    belongs_to :license, License
    belongs_to :org, Org

    timestamps()
  end

  @doc """
  Creates a changeset for a new quota.
  """
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :feature,
      :limit,
      :current_usage,
      :reset_period,
      :reset_at,
      :license_id,
      :org_id
    ])
    |> validate_required([:feature, :limit, :license_id, :org_id])
    |> validate_inclusion(:feature, @features)
    |> validate_inclusion(:reset_period, @reset_periods)
    |> validate_number(:limit, greater_than_or_equal_to: 0)
    |> validate_number(:current_usage, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:license_id)
    |> foreign_key_constraint(:org_id)
    |> unique_constraint([:feature, :org_id], name: :usage_quotas_feature_org_id_index)
  end

  @doc """
  Updates an existing quota.
  """
  def update_changeset(quota, attrs) do
    quota
    |> cast(attrs, [
      :limit,
      :current_usage,
      :reset_period,
      :reset_at
    ])
    |> validate_inclusion(:feature, @features)
    |> validate_inclusion(:reset_period, @reset_periods)
    |> validate_number(:limit, greater_than_or_equal_to: 0)
    |> validate_number(:current_usage, greater_than_or_equal_to: 0)
  end

  @doc """
  Checks if the quota has been exceeded.
  """
  def exceeded?(%__MODULE__{limit: limit, current_usage: current_usage}) when not is_nil(limit) do
    current_usage >= limit
  end

  def exceeded?(_), do: false

  @doc """
  Returns the remaining quota.
  Returns :unlimited if there's no limit.
  """
  def remaining(%__MODULE__{limit: nil}), do: :unlimited

  def remaining(%__MODULE__{limit: limit, current_usage: current_usage}) do
    max(0, limit - current_usage)
  end

  @doc """
  Calculates the usage percentage.
  Returns a float between 0 and 100.
  """
  def usage_percentage(%__MODULE__{limit: 0}), do: 0.0
  def usage_percentage(%__MODULE__{limit: nil}), do: 0.0

  def usage_percentage(%__MODULE__{limit: limit, current_usage: current_usage}) do
    min(100.0, current_usage / limit * 100)
  end

  @doc """
  Increments the current usage by the given amount.
  Returns a changeset with the updated usage.
  """
  def increment_usage(quota, amount) when is_integer(amount) and amount > 0 do
    update_changeset(quota, %{current_usage: quota.current_usage + amount})
  end

  @doc """
  Checks if the quota needs to be reset based on the reset period.
  """
  def needs_reset?(%__MODULE__{reset_period: nil}), do: false
  def needs_reset?(%__MODULE__{reset_at: nil}), do: true

  def needs_reset?(quota) do
    now = DateTime.utc_now()

    case quota.reset_period do
      "monthly" ->
        now.year > quota.reset_at.year or
          (now.year == quota.reset_at.year and now.month > quota.reset_at.month)

      "yearly" ->
        now.year > quota.reset_at.year

      _ ->
        false
    end
  end

  @doc """
  Resets the current usage to 0 and updates the reset_at timestamp.
  """
  def reset(quota) do
    update_changeset(quota, %{
      current_usage: 0,
      reset_at: DateTime.utc_now()
    })
  end
end
