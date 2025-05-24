defmodule PetalPro.Repo.Migrations.CreateMetricSnapshots do
  use Ecto.Migration

  def change do
    create table(:metric_snapshots) do
      add :metric_type, :string
      add :period_start, :date
      add :period_end, :date
      add :value, :decimal
      add :previous_value, :decimal
      add :change_percent, :decimal
      add :metadata, :map
      add :org_id, references(:orgs, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:metric_snapshots, [:org_id])
  end
end
