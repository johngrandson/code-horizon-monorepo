defmodule PetalPro.Repo.Migrations.UpdateOrgsTableWithWhitelabelProps do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :schema_prefix, :string
      add :primary_domain, :string

      add :plan, :string, default: "free"
      add :max_users, :integer, default: 5

      add :status, :string, default: "active"
      add :suspended_reason, :string

      add :settings, :map, default: %{}
    end

    create unique_index(:orgs, [:schema_prefix])

    create index(:orgs, [:primary_domain])
    create index(:orgs, [:status])
  end
end
