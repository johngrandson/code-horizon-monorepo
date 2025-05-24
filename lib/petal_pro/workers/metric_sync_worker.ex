defmodule PetalPro.Workers.MetricSyncWorker do
  @moduledoc false
  use Oban.Worker, queue: :default

  import Ecto.Query, warn: false

  alias PetalPro.Analytics
  alias PetalPro.Billing.Plans
  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Orgs.Org
  alias PetalPro.Repo

  require Logger

  @doc """
  Syncs revenue metrics for a specific organization.

  ## Examples

      iex> PetalPro.Workers.MetricSyncWorker.perform(%{args: %{"org_id" => 1}})
      :ok

      %{org_id: 4}
      |> PetalPro.Workers.MetricSyncWorker.new()
      |> Oban.insert()

  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"org_id" => org_id}}) do
    if Repo.exists?(Org, id: org_id) do
      sync_revenue_metrics(org_id)
      :ok
    else
      {:error, "Org not found"}
    end
  end

  defp sync_revenue_metrics(org_id) do
    current_month = Date.beginning_of_month(Date.utc_today())
    previous_month = current_month |> Date.add(-1) |> Date.beginning_of_month()

    # Usar dados existentes do billing
    current_revenue = get_monthly_revenue(org_id, current_month)
    previous_revenue = get_monthly_revenue(org_id, previous_month)

    change_percent = calculate_change_percent(current_revenue, previous_revenue)

    Analytics.create_metric_snapshot(%{
      org_id: org_id,
      metric_type: "revenue",
      period_start: current_month,
      period_end: Date.end_of_month(current_month),
      value: current_revenue,
      previous_value: previous_revenue,
      change_percent: change_percent
    })
  end

  defp get_monthly_revenue(org_id, month_start) do
    get_monthly_revenue_optimized(org_id, month_start)
  end

  # Versão otimizada - uma query só
  defp get_monthly_revenue_optimized(org_id, month_start) do
    alias PetalPro.Billing.Customers

    month_end = Date.end_of_month(month_start)
    customer = Customers.get_customer_by_source(:org, org_id)

    if customer do
      # Get all plans configured in the system
      plans_map = Map.new(Plans.plans(), &{&1.id, &1.amount})

      # Get active subscriptions and sum their plan amounts
      Subscriptions.list_subscriptions_query()
      |> where([s], s.billing_customer_id == ^customer.id)
      |> where([s], s.status in ["active", "trialing"])
      |> where([s], s.current_period_start <= ^month_end)
      |> where([s], s.current_period_end >= ^month_start)
      |> select([s], s.plan_id)
      |> Repo.all()
      |> Enum.reduce(Decimal.new("0"), fn plan_id, acc ->
        plan_amount = Map.get(plans_map, plan_id, 0)
        Decimal.add(acc, Decimal.new(plan_amount))
      end)
    else
      Decimal.new("0")
    end
  end

  defp calculate_change_percent(current, previous) do
    if Decimal.equal?(previous, 0) do
      Decimal.new("0")
    else
      current
      |> Decimal.sub(previous)
      |> Decimal.div(previous)
      |> Decimal.mult(100)
    end
  end
end
