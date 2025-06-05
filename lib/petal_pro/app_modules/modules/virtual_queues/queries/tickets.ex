defmodule PetalPro.AppModules.VirtualQueues.Tickets do
  @moduledoc """
  Context module for managing Tickets within a queue.
  Handles CRUD operations for tickets, status updates, and state transitions.
  """
  import Ecto.Query

  alias PetalPro.AppModules.VirtualQueues.Queue
  alias PetalPro.AppModules.VirtualQueues.Ticket
  alias PetalPro.Repo

  # Valid status transitions
  @valid_transitions %{
    waiting: [:called, :cancelled, :missed],
    called: [:serving, :missed, :cancelled],
    serving: [:completed, :cancelled],
    completed: [],
    # Allow re-calling missed tickets
    missed: [:called],
    cancelled: []
  }

  @doc """
  Lists tickets for a given queue with optional filters.

  ## Examples
      iex> list_tickets([status: :waiting], queue_id)
      [%Ticket{}, ...]
  """
  def list_tickets(filters \\ [], queue_id) when is_integer(queue_id) do
    Ticket
    |> where([t], t.queue_id == ^queue_id)
    |> apply_filters(filters)
    |> order_by([t], asc: t.ticket_number)
    |> Repo.all()
  end

  @doc """
  Applies dynamic filters to the ticket query.
  Only allows filtering on safe, predefined fields.
  """
  def apply_filters(query, filters) when is_list(filters) do
    allowed_fields = [:status, :ticket_number, :customer_name, :priority]

    Enum.reduce(filters, query, fn {key, value}, acc_query ->
      if key in allowed_fields do
        where(acc_query, [t], field(t, ^key) == ^value)
      else
        acc_query
      end
    end)
  end

  @doc """
  Gets a single ticket by ID, ensuring it belongs to the given queue.
  Raises `Ecto.NoResultsError` if the ticket is not found or doesn't belong to the queue.
  """
  def get_ticket!(id, queue_id) when is_integer(id) and is_integer(queue_id) do
    Ticket
    |> where([t], t.id == ^id and t.queue_id == ^queue_id)
    |> Repo.one!()
  end

  @doc """
  Gets a single ticket by ID, returning `nil` if not found or doesn't belong to the queue.
  """
  def get_ticket(id, queue_id) when is_integer(id) and is_integer(queue_id) do
    Ticket
    |> where([t], t.id == ^id and t.queue_id == ^queue_id)
    |> Repo.one()
  end

  @doc """
  Gets a ticket by its number within a queue.
  """
  def get_ticket_by_number(ticket_number, queue_id) when is_integer(ticket_number) and is_integer(queue_id) do
    Ticket
    |> where([t], t.ticket_number == ^ticket_number and t.queue_id == ^queue_id)
    |> Repo.one()
  end

  @doc """
  Creates a new ticket with a predefined ticket number.
  This function is primarily used by the `Queues` context after number generation.
  Includes validation to prevent duplicate ticket numbers.
  """
  def create_ticket_with_number(%Queue{} = queue, ticket_number, org_id, attrs \\ %{})
      when is_map(attrs) and is_integer(ticket_number) and is_integer(org_id) do
    # Validate ticket number is not already taken
    existing_ticket = get_ticket_by_number(ticket_number, queue.id)

    if existing_ticket do
      {:error, :ticket_number_taken}
    else
      attrs_with_queue =
        attrs
        |> Map.put(:queue_id, queue.id)
        |> Map.put(:ticket_number, ticket_number)
        |> Map.put(:status, :waiting)
        |> Map.put(:created_at, DateTime.utc_now())
        |> Map.put(:org_id, org_id)

      %Ticket{}
      |> Ticket.changeset(attrs_with_queue)
      |> Repo.insert()
    end
  end

  @doc """
  Updates an existing ticket with proper validation.
  """
  def update_ticket(%Ticket{} = ticket, attrs) when is_map(attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ticket.
  Only allows deletion of tickets that haven't been served.
  """
  def delete_ticket(%Ticket{status: status} = ticket) when status in [:waiting, :cancelled, :missed] do
    Repo.delete(ticket)
  end

  def delete_ticket(%Ticket{}) do
    {:error, :cannot_delete_served_ticket}
  end

  @doc """
  Deletes all tickets for queues belonging to a given organization.
  Uses proper join to ensure data consistency.
  """
  def delete_all_tickets_for_org(org_id) when is_integer(org_id) do
    ticket_subquery =
      from q in Queue,
        where: q.org_id == ^org_id,
        select: q.id

    Repo.delete_all(from(t in Ticket, where: t.queue_id in subquery(ticket_subquery)))
  end

  @doc """
  Returns a changeset for a ticket, useful for form building.
  """
  def change_ticket(%Ticket{} = ticket, attrs \\ %{}), do: Ticket.changeset(ticket, attrs)

  # Status transition functions with validation

  @doc """
  Sets the ticket status to `:called` and records the call time.
  Uses database locking to prevent race conditions.
  """
  def call_ticket(%Ticket{} = ticket) do
    update_ticket_status(ticket, :called, %{called_at: DateTime.utc_now()})
  end

  @doc """
  Sets the ticket status to `:serving` and records the served time.
  """
  def mark_serving(%Ticket{} = ticket) do
    update_ticket_status(ticket, :serving, %{served_at: DateTime.utc_now()})
  end

  @doc """
  Sets the ticket status to `:completed` and records the completion time.
  """
  def mark_completed(%Ticket{} = ticket) do
    update_ticket_status(ticket, :completed, %{completed_at: DateTime.utc_now()})
  end

  @doc """
  Sets the ticket status to `:missed`.
  """
  def mark_missed(%Ticket{} = ticket) do
    update_ticket_status(ticket, :missed, %{})
  end

  @doc """
  Sets the ticket status to `:cancelled`.
  """
  def mark_cancelled(%Ticket{} = ticket) do
    update_ticket_status(ticket, :cancelled, %{})
  end

  # Query helper functions

  @doc """
  Gets all tickets with a specific status for a queue.
  """
  def list_tickets_by_status(queue_id, status) when is_integer(queue_id) and is_atom(status) do
    Repo.all(from(t in Ticket, where: t.queue_id == ^queue_id and t.status == ^status, order_by: [asc: t.ticket_number]))
  end

  @doc """
  Gets the next waiting ticket in a queue (lowest ticket number).
  """
  def get_next_waiting_ticket(queue_id) when is_integer(queue_id) do
    Repo.one(
      from(t in Ticket,
        where: t.queue_id == ^queue_id and t.status == :waiting,
        order_by: [asc: t.ticket_number],
        limit: 1
      )
    )
  end

  @doc """
  Gets ticket statistics for a queue.
  """
  def get_ticket_stats(queue_id) when is_integer(queue_id) do
    stats =
      from(t in Ticket,
        where: t.queue_id == ^queue_id,
        group_by: t.status,
        select: {t.status, count(t.id)}
      )
      |> Repo.all()
      |> Map.new()

    %{
      total: Enum.reduce(stats, 0, fn {_, count}, acc -> acc + count end),
      waiting: Map.get(stats, :waiting, 0),
      called: Map.get(stats, :called, 0),
      serving: Map.get(stats, :serving, 0),
      completed: Map.get(stats, :completed, 0),
      missed: Map.get(stats, :missed, 0),
      cancelled: Map.get(stats, :cancelled, 0)
    }
  end

  @doc """
  Gets the average service time for completed tickets in a queue.
  Returns time in minutes.
  """
  def get_average_service_time(queue_id) when is_integer(queue_id) do
    result =
      Repo.one(
        from(t in Ticket,
          where:
            t.queue_id == ^queue_id and t.status == :completed and not is_nil(t.served_at) and not is_nil(t.completed_at),
          select: avg(fragment("EXTRACT(EPOCH FROM (? - ?))", t.completed_at, t.served_at))
        )
      )

    case result do
      nil -> 0.0
      # Convert to minutes
      seconds -> Float.round(seconds / 60.0, 2)
    end
  end

  # Private helper functions

  defp update_ticket_status(%Ticket{} = ticket, new_status, additional_attrs) do
    if valid_transition?(ticket.status, new_status) do
      Repo.transaction(fn ->
        # Lock the ticket to prevent concurrent modifications
        locked_ticket =
          Ticket
          |> where([t], t.id == ^ticket.id)
          |> lock("FOR UPDATE")
          |> Repo.one!()

        # Verify the status hasn't changed since we checked
        if locked_ticket.status == ticket.status do
          attrs = Map.put(additional_attrs, :status, new_status)

          case update_ticket(locked_ticket, attrs) do
            {:ok, updated_ticket} -> updated_ticket
            {:error, reason} -> Repo.rollback(reason)
          end
        else
          Repo.rollback(:status_changed_concurrently)
        end
      end)
    else
      {:error, {:invalid_transition, ticket.status, new_status}}
    end
  end

  defp valid_transition?(current_status, new_status) do
    allowed_transitions = Map.get(@valid_transitions, current_status, [])
    new_status in allowed_transitions
  end

  @doc """
  Checks if a status transition is valid.

  ## Examples
      iex> valid_status_transition?(:waiting, :called)
      true

      iex> valid_status_transition?(:completed, :serving)
      false
  """
  def valid_status_transition?(current_status, new_status) do
    valid_transition?(current_status, new_status)
  end

  @doc """
  Gets all valid next statuses for a ticket's current status.
  """
  def get_valid_next_statuses(current_status) when is_atom(current_status) do
    Map.get(@valid_transitions, current_status, [])
  end
end
