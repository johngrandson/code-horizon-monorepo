# lib/petal_pro/billing/limits.ex
defmodule PetalPro.Billing.Limits do
  @moduledoc """
  Handles plan limits for organizations.
  """

  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Orgs

  @doc """
  Gets the current plan limits for an organization.
  """
  def get_limits(org_id) do
    case Subscriptions.get_active_subscription_for_org(org_id) do
      nil ->
        # Default free plan limits
        %{
          max_users: 2,
          max_projects: 3,
          max_storage_mb: 1024
          # ... other limits
        }

      subscription ->
        # Get limits based on the subscription plan
        get_plan_limits(subscription.plan_id)
    end
  end

  defp get_plan_limits(plan_id) do
    # Define your plan limits here or fetch from config
    case plan_id do
      "free" -> %{max_users: 5, max_projects: 3, max_storage_mb: 1024}
      "starter" -> %{max_users: 10, max_projects: 5, max_storage_mb: 2048}
      "pro" -> %{max_users: 20, max_projects: 50, max_storage_mb: 10_240}
      "enterprise" -> %{max_users: :unlimited, max_projects: :unlimited, max_storage_mb: :unlimited}
      _ -> %{max_users: 5, max_projects: 3, max_storage_mb: 1024}
    end
  end

  @doc """
  Checks if an organization can invite more users.
  """
  def can_invite_user?(org_id) do
    limits = get_limits(org_id)
    current_count = Orgs.count_org_invitations(org_id)

    case limits.max_users do
      :unlimited -> true
      max -> current_count < max
    end
  end
end
