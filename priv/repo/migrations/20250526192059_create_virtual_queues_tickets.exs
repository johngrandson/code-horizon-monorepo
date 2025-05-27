defmodule PetalPro.Repo.Migrations.CreateVirtualQueuesTickets do
  use Ecto.Migration

  def change do
    create table(:virtual_queues_tickets) do
      # Ticket identification
      add :ticket_number, :integer, null: false
      add :status, :string, null: false, default: "waiting"

      # Customer information
      add :customer_name, :string
      add :customer_phone, :string
      add :customer_email, :string
      add :notes, :text

      # Priority and categorization
      add :priority, :string, default: "normal"
      add :service_type, :string

      # Status timestamps for tracking ticket lifecycle
      add :called_at, :utc_datetime
      add :served_at, :utc_datetime
      add :completed_at, :utc_datetime

      # Additional metadata stored as JSON
      add :metadata, :map, null: false, default: %{}

      # Foreign key to the queue this ticket belongs to
      add :queue_id, references(:virtual_queues_queues, on_delete: :delete_all), null: false

      timestamps()
    end

    # Primary indexes for performance
    create index(:virtual_queues_tickets, [:queue_id])
    create index(:virtual_queues_tickets, [:status])
    create index(:virtual_queues_tickets, [:ticket_number])

    # Composite indexes for common query patterns
    create index(:virtual_queues_tickets, [:queue_id, :status])
    create index(:virtual_queues_tickets, [:queue_id, :ticket_number])
    create index(:virtual_queues_tickets, [:queue_id, :status, :ticket_number])

    # Index for waiting tickets ordered by ticket number (FIFO)
    create index(:virtual_queues_tickets, [:queue_id, :ticket_number],
             name: :virtual_queues_tickets_waiting_order_index,
             where: "status = 'waiting'"
           )

    # Index for time-based queries and analytics
    create index(:virtual_queues_tickets, [:inserted_at])
    create index(:virtual_queues_tickets, [:queue_id, :inserted_at])

    # Unique constraint: ticket numbers must be unique within each queue
    create unique_index(:virtual_queues_tickets, [:queue_id, :ticket_number],
             name: :virtual_queues_tickets_queue_number_index
           )

    # Check constraints for data integrity
    create constraint(:virtual_queues_tickets, :ticket_number_positive,
             check: "ticket_number > 0"
           )

    create constraint(:virtual_queues_tickets, :valid_status,
             check:
               "status IN ('waiting', 'called', 'serving', 'completed', 'missed', 'cancelled')"
           )

    create constraint(:virtual_queues_tickets, :valid_priority,
             check: "priority IN ('low', 'normal', 'high', 'urgent')"
           )

    # Timestamp logic constraints
    create constraint(:virtual_queues_tickets, :called_before_served,
             check: "served_at IS NULL OR called_at IS NULL OR served_at >= called_at"
           )

    create constraint(:virtual_queues_tickets, :served_before_completed,
             check: "completed_at IS NULL OR served_at IS NULL OR completed_at >= served_at"
           )
  end
end
