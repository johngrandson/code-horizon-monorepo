defmodule PetalPro.Repo.Migrations.CreateLicenses do
  use Ecto.Migration

  def change do
    create table(:licenses) do
      add :key, :string, null: false
      # subscription, perpetual, trial
      add :type, :string, null: false
      # active, expired, revoked
      add :status, :string, null: false, default: "active"
      add :starts_at, :utc_datetime
      add :expires_at, :utc_datetime
      add :max_users, :integer
      add :max_storage_mb, :integer
      add :features, :map, default: %{}
      add :metadata, :map, default: %{}

      # License is linked to an org
      add :org_id, references(:orgs, on_delete: :delete_all, type: :integer), null: false

      timestamps()
    end

    create unique_index(:licenses, [:key])
    create index(:licenses, [:org_id])
    create index(:licenses, [:status])
    create index(:licenses, [:expires_at])
  end
end
