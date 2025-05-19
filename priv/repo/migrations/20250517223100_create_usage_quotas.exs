defmodule PetalPro.Repo.Migrations.CreateUsageQuotas do
  use Ecto.Migration

  def change do
    create table(:usage_quotas) do
      # Ex: "storage_mb", "active_users", "api_calls"
      add :feature, :string, null: false
      add :limit, :integer, null: false
      add :current_usage, :integer, default: 0
      # monthly, yearly, never
      add :reset_period, :string
      add :reset_at, :utc_datetime

      add :license_id, references(:licenses, on_delete: :delete_all)
      add :org_id, references(:orgs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:usage_quotas, [:license_id])
    create index(:usage_quotas, [:org_id])
    create index(:usage_quotas, [:feature, :org_id], unique: true)
  end
end
