defmodule PetalPro.Repo.Migrations.CreateUsageRecords do
  use Ecto.Migration

  def change do
    create table(:usage_records) do
      add :feature, :string, null: false
      add :amount, :integer, null: false
      add :recorded_at, :utc_datetime, null: false
      add :metadata, :map, default: %{}
      add :license_id, references(:licenses, on_delete: :delete_all), null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:usage_records, [:license_id])
    create index(:usage_records, [:org_id])
    create index(:usage_records, [:user_id])
    create index(:usage_records, [:feature])
    create index(:usage_records, [:recorded_at])
  end
end
