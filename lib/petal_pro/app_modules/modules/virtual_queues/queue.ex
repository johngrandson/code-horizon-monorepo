defmodule PetalPro.AppModules.VirtualQueues.Queue do
  @moduledoc """
  Ecto schema for a virtual queue.

  Queues are associated with a specific organization and manage ticket issuance
  and calling workflows. Each queue maintains counters for issued and served tickets.
  """
  use PetalPro.Schema

  import Ecto.Query

  alias PetalPro.AppModules.VirtualQueues.Ticket
  alias PetalPro.Orgs.Org

  @status_values [:active, :inactive, :paused]

  typed_schema "virtual_queues_queues" do
    field :name, :string
    field :description, :string
    field :status, Ecto.Enum, values: @status_values, default: :active

    # Ticket counters - should only be modified through specific operations
    field :current_ticket_number, :integer, default: 0
    field :last_served_ticket_number, :integer, default: 0

    # Queue configuration
    field :daily_reset, :boolean, default: false
    field :max_tickets_per_day, :integer
    field :is_active, :boolean, default: true

    # Additional metadata stored as JSON
    field :settings, :map, default: %{}

    # Status change timestamps
    field :activated_at, :utc_datetime
    field :paused_at, :utc_datetime

    # Soft delete support
    field :deleted_at, :utc_datetime

    # Associations
    belongs_to :org, Org, type: :id
    has_many :tickets, Ticket, foreign_key: :queue_id

    timestamps()
  end

  @doc """
  Changeset for creating a new queue.
  Only allows setting basic queue information.
  """
  def create_changeset(queue, attrs) do
    queue
    |> cast(attrs, [:name, :description, :org_id, :daily_reset, :max_tickets_per_day, :settings])
    |> validate_required([:name, :org_id])
    |> validate_basic_fields()
    |> validate_org_association()
    |> put_activation_timestamp()
    |> unique_constraint([:name, :org_id],
      name: :virtual_queues_queues_name_org_id_index,
      message: "a queue with this name already exists for this organization"
    )
  end

  @doc """
  Changeset for updating queue information.
  Does not allow modification of critical counters.
  """
  def update_changeset(queue, attrs) do
    queue
    |> cast(attrs, [:name, :description, :daily_reset, :max_tickets_per_day, :settings])
    |> validate_basic_fields()
    |> maybe_unique_constraint_on_name_change()
  end

  @doc """
  Changeset for updating queue status.
  Handles status transitions and related timestamps.
  """
  def status_changeset(queue, new_status) when new_status in @status_values do
    changeset =
      queue
      |> cast(%{status: new_status}, [:status])
      |> validate_required([:status])
      |> validate_status_transition(queue.status, new_status)

    # Set appropriate timestamps based on status
    case new_status do
      :active -> put_change(changeset, :activated_at, DateTime.truncate(DateTime.utc_now(), :second))
      :paused -> put_change(changeset, :paused_at, DateTime.truncate(DateTime.utc_now(), :second))
      _ -> changeset
    end
  end

  @doc """
  Changeset for updating ticket counters.
  Should only be used by the queue management system.
  """
  def counter_changeset(queue, attrs) do
    queue
    |> cast(attrs, [:current_ticket_number, :last_served_ticket_number])
    |> validate_counter_consistency()
    |> validate_counter_progression(queue)
  end

  @doc """
  Changeset for soft deletion.
  """
  def delete_changeset(queue) do
    change(queue, %{
      deleted_at: DateTime.truncate(DateTime.utc_now(), :second),
      status: :inactive,
      is_active: false
    })
  end

  @doc """
  Changeset for daily reset operations.
  Resets counters to 0 if daily_reset is enabled.
  """
  def daily_reset_changeset(queue) do
    if queue.daily_reset do
      change(queue, %{
        current_ticket_number: 0,
        last_served_ticket_number: 0
      })
    else
      change(queue, %{})
    end
  end

  # Private validation functions

  defp validate_basic_fields(changeset) do
    changeset
    |> validate_length(:name, min: 1, max: 100, message: "must be between 1 and 100 characters")
    |> validate_length(:description, max: 500, message: "must not exceed 500 characters")
    |> validate_number(:max_tickets_per_day, greater_than: 0, message: "must be greater than 0")
    |> trim_string_fields()
  end

  defp trim_string_fields(changeset) do
    changeset
    |> update_change(:name, &String.trim/1)
    |> update_change(:description, &String.trim/1)
    |> validate_change(:name, fn :name, name ->
      if String.trim(name) == "", do: [name: "cannot be blank"], else: []
    end)
  end

  defp validate_org_association(changeset) do
    foreign_key_constraint(changeset, :org_id,
      name: :virtual_queues_queues_org_id_fkey,
      message: "organization does not exist"
    )
  end

  defp validate_counter_consistency(changeset) do
    current_number = get_field(changeset, :current_ticket_number)
    last_served_number = get_field(changeset, :last_served_ticket_number)

    cond do
      current_number < 0 ->
        add_error(changeset, :current_ticket_number, "cannot be negative")

      last_served_number < 0 ->
        add_error(changeset, :last_served_ticket_number, "cannot be negative")

      current_number < last_served_number ->
        add_error(changeset, :current_ticket_number, "cannot be less than last served ticket number")

      true ->
        changeset
    end
  end

  defp validate_counter_progression(changeset, original_queue) do
    new_current = get_field(changeset, :current_ticket_number)
    new_last_served = get_field(changeset, :last_served_ticket_number)

    cond do
      new_current < original_queue.current_ticket_number ->
        add_error(changeset, :current_ticket_number, "cannot decrease (except during daily reset)")

      new_last_served < original_queue.last_served_ticket_number ->
        add_error(changeset, :last_served_ticket_number, "cannot decrease (except during daily reset)")

      true ->
        changeset
    end
  end

  defp validate_status_transition(changeset, current_status, new_status) do
    valid_transitions = %{
      active: [:inactive, :paused],
      inactive: [:active],
      paused: [:active, :inactive]
    }

    allowed = Map.get(valid_transitions, current_status, [])

    if new_status in allowed do
      changeset
    else
      add_error(changeset, :status, "invalid status transition from #{current_status} to #{new_status}")
    end
  end

  defp put_activation_timestamp(changeset) do
    if get_field(changeset, :status) == :active do
      put_change(changeset, :activated_at, DateTime.truncate(DateTime.utc_now(), :second))
    else
      changeset
    end
  end

  defp maybe_unique_constraint_on_name_change(changeset) do
    if get_change(changeset, :name) do
      unique_constraint(changeset, [:name, :org_id],
        name: :virtual_queues_queues_name_org_id_index,
        message: "a queue with this name already exists for this organization"
      )
    else
      changeset
    end
  end

  # Query helpers (commonly used queries as functions)

  @doc """
  Query for active queues only.
  """
  def active_queues(query \\ __MODULE__) do
    from q in query,
      where: q.status == :active and is_nil(q.deleted_at)
  end

  @doc """
  Query for queues by organization.
  """
  def by_org(query \\ __MODULE__, org_id) do
    from q in query, where: q.org_id == ^org_id
  end

  @doc """
  Query for non-deleted queues.
  """
  def not_deleted(query \\ __MODULE__) do
    from q in query, where: is_nil(q.deleted_at)
  end

  # Helper functions

  @doc """
  Returns true if the queue is currently operational (active and not deleted).
  """
  def operational?(%__MODULE__{status: :active, deleted_at: nil}), do: true
  def operational?(_), do: false

  @doc """
  Returns true if the queue has reached its daily ticket limit.
  """
  def daily_limit_reached?(%__MODULE__{max_tickets_per_day: nil}), do: false

  def daily_limit_reached?(%__MODULE__{max_tickets_per_day: limit, current_ticket_number: current}) do
    current >= limit
  end

  @doc """
  Returns the number of tickets currently waiting to be served.
  """
  def tickets_in_queue(%__MODULE__{current_ticket_number: current, last_served_ticket_number: served}) do
    max(0, current - served)
  end

  @doc """
  Returns all possible status values.
  """
  def status_values, do: @status_values
end
