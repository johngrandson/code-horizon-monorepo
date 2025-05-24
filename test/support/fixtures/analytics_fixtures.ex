defmodule PetalPro.AnalyticsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.Analytics` context.
  """

  @doc """
  Generate a metric_snapshot.
  """
  def metric_snapshot_fixture(attrs \\ %{}) do
    {:ok, metric_snapshot} =
      attrs
      |> Enum.into(%{
        change_percent: "120.5",
        metadata: %{},
        metric_type: "some metric_type",
        period_end: ~D[2025-05-22],
        period_start: ~D[2025-05-22],
        previous_value: "120.5",
        value: "120.5"
      })
      |> PetalPro.Analytics.create_metric_snapshot()

    metric_snapshot
  end
end
