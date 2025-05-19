defmodule PetalPro.Licenses.UsageRecord do
  @moduledoc """
  Schema representing a usage record for tracking feature usage over time.

  Used to track when and how much of a particular feature has been used,
  which is essential for billing and quota enforcement.
  """
  use PetalPro.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias PetalPro.Accounts.User
  alias PetalPro.Licenses.License
  alias PetalPro.Orgs.Org

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @features ["storage_mb", "active_users", "api_calls"]

  typed_schema "usage_records" do
    field :feature, :string
    field :amount, :integer
    field :recorded_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :license, License
    belongs_to :org, Org
    belongs_to :user, User

    timestamps()
  end

  @doc """
  Creates a changeset for a new usage record.
  """
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :feature,
      :amount,
      :recorded_at,
      :metadata,
      :license_id,
      :org_id,
      :user_id
    ])
    |> validate_required([:feature, :amount, :recorded_at, :license_id, :org_id])
    |> validate_inclusion(:feature, @features)
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:license_id)
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Helper function to create a new usage record with the current timestamp.
  """
  def record_usage(license_id, org_id, feature, amount, opts \\ []) do
    now = opts[:recorded_at] || DateTime.utc_now()
    metadata = opts[:metadata] || %{}
    user_id = opts[:user_id]

    create_changeset(%{
      license_id: license_id,
      org_id: org_id,
      user_id: user_id,
      feature: feature,
      amount: amount,
      recorded_at: now,
      metadata: metadata
    })
  end

  @doc """
  Gets the total usage for a specific feature within a date range.

  ## Examples

      # Get storage usage for the current month
      start_date = ~D[2023-01-01]
      end_date = ~D[2023-01-31]
      UsageRecord.get_usage("storage_mb", org_id, start_date, end_date)
  """
  def get_usage(feature, org_id, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59.999999])

    query =
      from r in __MODULE__,
        where: r.feature == ^feature,
        where: r.org_id == ^org_id,
        where: r.recorded_at >= ^start_datetime,
        where: r.recorded_at <= ^end_datetime,
        select: sum(r.amount)

    case PetalPro.Repo.one(query) do
      nil -> 0
      total -> total
    end
  end

  @doc """
  Gets the daily usage for a specific feature within a date range.

  Returns a map with dates as keys and usage amounts as values.

  ## Examples

      # Get daily storage usage for January 2023
      start_date = ~D[2023-01-01]
      end_date = ~D[2023-01-31]
      usage = UsageRecord.get_daily_usage("storage_mb", org_id, start_date, end_date)
      # => %{~D[2023-01-01] => 1024, ~D[2023-01-02] => 2048, ...}
  """
  def get_daily_usage(feature, org_id, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59.999999])

    from(
      r in __MODULE__,
      where: r.feature == ^feature,
      where: r.org_id == ^org_id,
      where: r.recorded_at >= ^start_datetime,
      where: r.recorded_at <= ^end_datetime,
      group_by: fragment("date_trunc('day', recorded_at)"),
      order_by: [asc: fragment("date_trunc('day', recorded_at)")],
      select: {
        fragment("date_trunc('day', recorded_at)::date"),
        coalesce(sum(r.amount), 0)
      }
    )
    |> PetalPro.Repo.all()
    |> Map.new()
  end
end
