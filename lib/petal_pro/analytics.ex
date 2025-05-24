defmodule PetalPro.Analytics do
  @moduledoc false
  import Ecto.Query, warn: false

  alias PetalPro.Analytics.MetricSnapshot
  alias PetalPro.Repo

  def list_metric_snapshots(filters \\ []) do
    MetricSnapshot
    |> apply_filters(filters)
    |> Repo.all()
  end

  def get_metric_snapshot!(id), do: Repo.get!(MetricSnapshot, id)

  def get_latest_metric(org_id, metric_type) do
    MetricSnapshot
    |> where([m], m.org_id == ^org_id and m.metric_type == ^metric_type)
    |> order_by([m], desc: m.period_end)
    |> limit(1)
    |> Repo.one()
  end

  def create_metric_snapshot(attrs \\ %{}) do
    %MetricSnapshot{}
    |> MetricSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  def update_metric_snapshot(%MetricSnapshot{} = snapshot, attrs) do
    snapshot
    |> MetricSnapshot.changeset(attrs)
    |> Repo.update()
  end

  def delete_metric_snapshot(%MetricSnapshot{} = snapshot) do
    Repo.delete(snapshot)
  end

  def change_metric_snapshot(%MetricSnapshot{} = snapshot, attrs \\ %{}) do
    MetricSnapshot.changeset(snapshot, attrs)
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:org_id, org_id}, query ->
        where(query, [m], m.org_id == ^org_id)

      {:metric_type, type}, query ->
        where(query, [m], m.metric_type == ^type)

      {:period_range, {start_date, end_date}}, query ->
        where(query, [m], m.period_start >= ^start_date and m.period_end <= ^end_date)

      _, query ->
        query
    end)
  end
end
