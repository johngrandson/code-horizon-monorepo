defmodule PetalPro.AnalyticsTest do
  use PetalPro.DataCase

  alias PetalPro.Analytics

  describe "metric_snapshots" do
    alias PetalPro.Analytics.MetricSnapshot

    import PetalPro.AnalyticsFixtures

    @invalid_attrs %{value: nil, metadata: nil, metric_type: nil, period_start: nil, period_end: nil, previous_value: nil, change_percent: nil}

    test "list_metric_snapshots/0 returns all metric_snapshots" do
      metric_snapshot = metric_snapshot_fixture()
      assert Analytics.list_metric_snapshots() == [metric_snapshot]
    end

    test "get_metric_snapshot!/1 returns the metric_snapshot with given id" do
      metric_snapshot = metric_snapshot_fixture()
      assert Analytics.get_metric_snapshot!(metric_snapshot.id) == metric_snapshot
    end

    test "create_metric_snapshot/1 with valid data creates a metric_snapshot" do
      valid_attrs = %{value: "120.5", metadata: %{}, metric_type: "some metric_type", period_start: ~D[2025-05-22], period_end: ~D[2025-05-22], previous_value: "120.5", change_percent: "120.5"}

      assert {:ok, %MetricSnapshot{} = metric_snapshot} = Analytics.create_metric_snapshot(valid_attrs)
      assert metric_snapshot.value == Decimal.new("120.5")
      assert metric_snapshot.metadata == %{}
      assert metric_snapshot.metric_type == "some metric_type"
      assert metric_snapshot.period_start == ~D[2025-05-22]
      assert metric_snapshot.period_end == ~D[2025-05-22]
      assert metric_snapshot.previous_value == Decimal.new("120.5")
      assert metric_snapshot.change_percent == Decimal.new("120.5")
    end

    test "create_metric_snapshot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Analytics.create_metric_snapshot(@invalid_attrs)
    end

    test "update_metric_snapshot/2 with valid data updates the metric_snapshot" do
      metric_snapshot = metric_snapshot_fixture()
      update_attrs = %{value: "456.7", metadata: %{}, metric_type: "some updated metric_type", period_start: ~D[2025-05-23], period_end: ~D[2025-05-23], previous_value: "456.7", change_percent: "456.7"}

      assert {:ok, %MetricSnapshot{} = metric_snapshot} = Analytics.update_metric_snapshot(metric_snapshot, update_attrs)
      assert metric_snapshot.value == Decimal.new("456.7")
      assert metric_snapshot.metadata == %{}
      assert metric_snapshot.metric_type == "some updated metric_type"
      assert metric_snapshot.period_start == ~D[2025-05-23]
      assert metric_snapshot.period_end == ~D[2025-05-23]
      assert metric_snapshot.previous_value == Decimal.new("456.7")
      assert metric_snapshot.change_percent == Decimal.new("456.7")
    end

    test "update_metric_snapshot/2 with invalid data returns error changeset" do
      metric_snapshot = metric_snapshot_fixture()
      assert {:error, %Ecto.Changeset{}} = Analytics.update_metric_snapshot(metric_snapshot, @invalid_attrs)
      assert metric_snapshot == Analytics.get_metric_snapshot!(metric_snapshot.id)
    end

    test "delete_metric_snapshot/1 deletes the metric_snapshot" do
      metric_snapshot = metric_snapshot_fixture()
      assert {:ok, %MetricSnapshot{}} = Analytics.delete_metric_snapshot(metric_snapshot)
      assert_raise Ecto.NoResultsError, fn -> Analytics.get_metric_snapshot!(metric_snapshot.id) end
    end

    test "change_metric_snapshot/1 returns a metric_snapshot changeset" do
      metric_snapshot = metric_snapshot_fixture()
      assert %Ecto.Changeset{} = Analytics.change_metric_snapshot(metric_snapshot)
    end
  end
end
