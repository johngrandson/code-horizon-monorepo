defmodule PetalPro.Repo.Migrations.CreateBillingTables do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:billing_customers) do
      add :email, :citext
      add :provider, :string, null: false
      add :provider_customer_id, :string, null: false

      # Add foreign keys for sources of customers here. In our case either a user or an org can be a source of a customer.
      add :user_id, references(:users, on_delete: :delete_all)
      add :org_id, references(:orgs, on_delete: :delete_all)

      timestamps()
    end

    create index(:billing_customers, [:user_id, :org_id])
    create index(:billing_customers, [:provider])

    create table(:billing_subscriptions) do
      add :status, :string, null: false
      add :plan_id, :string, null: false
      add :provider_subscription_id, :string, null: false
      add :provider_subscription_items, {:array, :map}, null: false
      add :cancel_at, :naive_datetime
      add :canceled_at, :naive_datetime
      add :current_period_end_at, :naive_datetime
      add :current_period_start, :naive_datetime

      add :billing_customer_id, references(:billing_customers, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:billing_subscriptions, [:billing_customer_id])
  end
end
