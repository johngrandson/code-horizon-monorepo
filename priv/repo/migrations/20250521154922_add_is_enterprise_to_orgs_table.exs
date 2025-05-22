defmodule PetalPro.Repo.Migrations.AddIsEnterpriseToOrgsTable do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :is_enterprise, :boolean, default: false
    end
  end
end
