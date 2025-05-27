defmodule PetalPro.Repo.Migrations.CreateVirtualQueuesQueues do
  use Ecto.Migration

  def change do
    create table(:virtual_queues_queues) do
      # Basic queue information
      add :name, :string, null: false, size: 100
      add :description, :text
      add :status, :string, null: false, default: "active"

      # Ticket counters - critical for queue operations
      add :current_ticket_number, :integer, null: false, default: 0
      add :last_served_ticket_number, :integer, null: false, default: 0

      # Queue configuration
      add :daily_reset, :boolean, null: false, default: false
      add :max_tickets_per_day, :integer
      add :is_active, :boolean, null: false, default: true

      # Additional settings stored as JSON
      add :settings, :map, null: false, default: %{}

      # Status change timestamps for audit trail
      add :activated_at, :utc_datetime
      add :paused_at, :utc_datetime

      # Soft delete support
      add :deleted_at, :utc_datetime

      # Foreign key to organizations (tenant/org-based queues)
      add :org_id, references(:orgs, on_delete: :delete_all), null: false

      timestamps()
    end

    # Primary indexes for performance
    create index(:virtual_queues_queues, [:org_id])
    create index(:virtual_queues_queues, [:status])
    create index(:virtual_queues_queues, [:is_active])
    create index(:virtual_queues_queues, [:deleted_at])

    # Composite indexes for common query patterns
    create index(:virtual_queues_queues, [:org_id, :status])
    create index(:virtual_queues_queues, [:org_id, :is_active])
    create index(:virtual_queues_queues, [:org_id, :deleted_at])

    create index(:virtual_queues_queues, [:org_id, :status, :is_active, :deleted_at],
             name: :virtual_queues_queues_operational_index
           )
  end
end
