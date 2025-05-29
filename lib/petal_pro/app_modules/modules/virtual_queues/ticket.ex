defmodule PetalPro.AppModules.VirtualQueues.Ticket do
  @moduledoc """
  Ecto schema for a ticket in a virtual queue.
  Tickets are associated with a specific queue.
  """
  use PetalPro.Schema

  alias PetalPro.AppModules.VirtualQueues

  # Defines the database table name
  typed_schema "virtual_queues_tickets" do
    field :ticket_number, :integer
    field :status, Ecto.Enum, values: [:waiting, :called, :serving, :completed, :missed, :cancelled], default: :waiting
    field :customer_name, :string
    # E.g., phone number or email for notifications
    field :customer_phone, :string
    # When the ticket was called
    field :called_at, :naive_datetime
    # When the customer started being served
    field :served_at, :naive_datetime
    # When the service was completed
    field :completed_at, :naive_datetime

    # Foreign key to the Queue
    belongs_to :queue, VirtualQueues.Queue, type: :integer
    # Optional: Foreign key to the User who obtained the ticket
    belongs_to :customer, PetalPro.Accounts.User, type: :integer, foreign_key: :customer_id

    timestamps()
  end

  @doc """
  Returns a changeset for creating or updating a Ticket.
  """
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [
      :ticket_number,
      :status,
      :customer_name,
      :customer_phone,
      :queue_id,
      :customer_id,
      :called_at,
      :served_at,
      :completed_at
    ])
    |> validate_required([:ticket_number, :status, :queue_id])
    # Ensures that ticket numbers are unique within a specific queue
    |> unique_constraint(:ticket_number,
      name: :virtual_queues_tickets_ticket_number_queue_id_index,
      message: "a ticket with this number already exists in this queue"
    )
  end
end
