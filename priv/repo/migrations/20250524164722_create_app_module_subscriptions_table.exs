defmodule PetalPro.Repo.Migrations.CreateAppModuleSubscriptionsTable do
  use Ecto.Migration

  def change do
    create table(:app_module_subscriptions) do
      add :module_code, :string
      add :active, :boolean, default: false
      add :expires_at, :utc_datetime

      add :org_id, references(:orgs, on_delete: :nothing)

      timestamps()
    end

    create index(:app_module_subscriptions, [:org_id])
    create unique_index(:app_module_subscriptions, [:org_id, :module_code])
  end
end
