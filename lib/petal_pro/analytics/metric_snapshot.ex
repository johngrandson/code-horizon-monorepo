defmodule PetalPro.Analytics.MetricSnapshot do
  @moduledoc false
  use PetalPro.Schema

  typed_schema "metric_snapshots" do
    field :metric_type, :string
    field :period_start, :date
    field :period_end, :date
    field :value, :decimal
    field :previous_value, :decimal
    field :change_percent, :decimal
    field :metadata, :map, default: %{}

    belongs_to :org, PetalPro.Orgs.Org

    timestamps()
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [
      :metric_type,
      :period_start,
      :period_end,
      :value,
      :previous_value,
      :change_percent,
      :metadata,
      :org_id
    ])
    |> validate_required([:metric_type, :period_start, :period_end, :value, :org_id])
    |> unique_constraint([:org_id, :metric_type, :period_start])
  end
end
