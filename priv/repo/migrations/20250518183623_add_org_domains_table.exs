defmodule PetalPro.Repo.Migrations.CreateOrgDomainsTable do
  use Ecto.Migration

  def change do
    create table(:org_domains) do
      add :domain, :string, null: false
      add :is_primary, :boolean, default: false, null: false
      add :verified_at, :utc_datetime
      add :verification_code, :string

      # DNS configuration
      add :dns_configured, :boolean, default: false
      add :dns_checked_at, :utc_datetime

      # SSL configuration
      add :ssl_enabled, :boolean, default: false
      add :ssl_expires_at, :utc_datetime

      add :org_id, references(:orgs, on_delete: :delete_all, type: :integer), null: false

      timestamps()
    end

    create unique_index(:org_domains, [:domain])
    create index(:org_domains, [:org_id])
  end
end
