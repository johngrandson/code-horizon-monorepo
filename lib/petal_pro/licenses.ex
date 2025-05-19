defmodule PetalPro.Licences do
  @moduledoc """
  The Licenses context handles all business logic related to software Licenses,
  including license management, quotas, and usage tracking.
  """

  import Ecto.Query, warn: false

  alias PetalPro.Licenses.License
  alias PetalPro.Licenses.Quota
  alias PetalPro.Licenses.UsageRecord
  alias PetalPro.Repo

  @doc """
  Returns the list of licenses for a given tenant.
  """
  def list_licenses(tenant_id) do
    License
    |> where([l], l.tenant_id == ^tenant_id)
    |> Repo.all()
  end

  @doc """
  Gets a single license by ID and ensures it belongs to the given tenant.
  """
  def get_license!(id, tenant_id) do
    License
    |> where([l], l.tenant_id == ^tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a new license for a tenant.
  """
  def create_license(attrs) do
    attrs
    |> License.create_changeset()
    |> Repo.insert()
  end

  @doc """
  Updates an existing license.
  """
  def update_license(%License{} = license, attrs) do
    license
    |> License.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a license.
  """
  def delete_license(%License{} = license) do
    Repo.delete(license)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking license changes.
  """
  def change_license(%License{} = license, attrs \\ %{}) do
    License.update_changeset(license, attrs)
  end

  # Quota related functions

  @doc """
  Gets a quota for a specific feature and tenant.
  """
  def get_quota(tenant_id, feature) do
    Quota
    |> where([q], q.tenant_id == ^tenant_id and q.feature == ^feature)
    |> Repo.one()
  end

  @doc """
  Creates or updates a quota for a specific feature and tenant.
  """
  def set_quota(tenant_id, feature, limit, reset_period \\ nil) do
    attrs = %{
      tenant_id: tenant_id,
      feature: feature,
      limit: limit,
      reset_period: reset_period
    }

    case get_quota(tenant_id, feature) do
      nil ->
        attrs
        |> Quota.create_changeset()
        |> Repo.insert()

      quota ->
        quota
        |> Quota.update_changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Records usage for a specific feature and tenant.
  """
  def record_usage(tenant_id, license_id, feature, amount, user_id \\ nil, metadata \\ %{}) do
    # Check if we need to reset the quota based on the reset period
    if quota = get_quota(tenant_id, feature) do
      if Quota.needs_reset?(quota) do
        {:ok, _} = quota |> Quota.reset() |> Repo.update()
      end
    end

    # Record the usage
    license_id
    |> UsageRecord.record_usage(tenant_id, feature, amount,
      user_id: user_id,
      metadata: metadata,
      recorded_at: DateTime.utc_now()
    )
    |> Repo.insert()
  end

  @doc """
  Checks if a feature is available within the quota limits.
  """
  def check_quota(tenant_id, feature, required_amount \\ 1) do
    case get_quota(tenant_id, feature) do
      nil ->
        {:ok, :unlimited}

      quota ->
        if quota.limit >= quota.current_usage + required_amount do
          {:ok, :available}
        else
          {:error, :quota_exceeded}
        end
    end
  end

  @doc """
  Gets the current usage for a specific feature and tenant within a date range.
  """
  def get_usage(tenant_id, feature, start_date, end_date) do
    UsageRecord.get_usage(feature, tenant_id, start_date, end_date)
  end

  @doc """
  Gets the daily usage for a specific feature and tenant within a date range.
  """
  def get_daily_usage(tenant_id, feature, start_date, end_date) do
    UsageRecord.get_daily_usage(feature, tenant_id, start_date, end_date)
  end

  @doc """
  Checks if a license is currently active.
  """
  def license_active?(%License{} = license) do
    License.active?(license)
  end

  @doc """
  Returns the remaining days until the license expires.
  """
  def days_until_expiration(%License{} = license) do
    License.days_until_expiration(license)
  end
end
