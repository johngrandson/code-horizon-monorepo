defmodule PetalPro.Repo.Migrations.AddCustomerIdToLogs do
  use Ecto.Migration

  def change do
    alter table(:logs) do
      add(:billing_customer_id, references(:billing_customers, on_delete: :delete_all))
    end

    create(index(:logs, [:billing_customer_id]))
  end
end
