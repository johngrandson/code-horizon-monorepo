defmodule PetalPro.AppModules.VirtualQueues.Queues do
  @moduledoc """
  Context module for managing Virtual Queues.
  Handles CRUD operations for queues and orchestrates ticket creation/calling logic.
  """
  import Ecto.Query

  alias PetalPro.AppModules.VirtualQueues.Queue
  alias PetalPro.AppModules.VirtualQueues.Ticket
  alias PetalPro.AppModules.VirtualQueues.Tickets
  alias PetalPro.Repo

  @doc """
  Lists all active queues for a given organization with optional filters.

  ## Examples
      iex> list_queues([status: :active], org_id)
      [%Queue{}, ...]

      iex> list_queues([], org_id, include_inactive: true)
      [%Queue{}, ...]
  """
  def list_queues(filters \\ [], org_id, opts \\ []) when is_integer(org_id) do
    base_query =
      Queue
      |> Queue.by_org(org_id)
      |> Queue.not_deleted()

    # Apply active filter unless explicitly including inactive
    base_query =
      if Keyword.get(opts, :include_inactive, false) do
        base_query
      else
        Queue.active_queues(base_query)
      end

    base_query
    |> apply_filters(filters)
    |> order_by([q], asc: q.name)
    |> Repo.all()
  end

  @doc """
  Lists only operational queues (active and not deleted).
  """
  def list_operational_queues(org_id) when is_integer(org_id) do
    Queue
    |> Queue.by_org(org_id)
    |> Queue.active_queues()
    |> where([q], q.is_active == true)
    |> order_by([q], asc: q.name)
    |> Repo.all()
  end

  @doc """
  Applies dynamic filters to the queue query.
  Only allows filtering on safe, predefined fields.
  """
  def apply_filters(query, filters) when is_list(filters) do
    allowed_fields = [:status, :name, :is_active, :daily_reset]

    Enum.reduce(filters, query, fn {key, value}, acc_query ->
      if key in allowed_fields do
        where(acc_query, [q], field(q, ^key) == ^value)
      else
        acc_query
      end
    end)
  end

  @doc """
  Gets a single queue by ID, ensuring it belongs to the given organization and is not deleted.
  Raises `Ecto.NoResultsError` if the queue is not found, deleted, or doesn't belong to the org.
  """
  def get_queue!(id, org_id) when is_integer(id) and is_integer(org_id) do
    Queue
    |> Queue.by_org(org_id)
    |> Queue.not_deleted()
    |> where([q], q.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Gets a single queue by ID, returning `nil` if not found, deleted, or doesn't belong to the organization.
  """
  def get_queue(id, org_id) when is_integer(id) and is_integer(org_id) do
    Queue
    |> Queue.by_org(org_id)
    |> Queue.not_deleted()
    |> where([q], q.id == ^id)
    |> Repo.one()
  end

  @doc """
  Gets a queue by name within an organization.
  """
  def get_queue_by_name(name, org_id) when is_binary(name) and is_integer(org_id) do
    Queue
    |> Queue.by_org(org_id)
    |> Queue.not_deleted()
    |> where([q], q.name == ^name)
    |> Repo.one()
  end

  @doc """
  Creates a new queue for an organization using the specialized create changeset.

  ## Examples
      iex> create_queue(%{name: "Customer Service", daily_reset: true}, org_id)
      {:ok, %Queue{}}
  """
  def create_queue(attrs, org_id) when is_map(attrs) and is_integer(org_id) do
    attrs_with_org = Map.put(attrs, :org_id, org_id)

    %Queue{}
    |> Queue.create_changeset(attrs_with_org)
    |> Repo.insert()
  end

  @doc """
  Updates an existing queue using the safe update changeset.
  This prevents modification of critical counter fields.
  """
  def update_queue(%Queue{} = queue, attrs) when is_map(attrs) do
    queue
    |> Queue.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates queue status with proper validation and timestamp tracking.
  """
  def update_queue_status(%Queue{} = queue, new_status) when new_status in [:active, :inactive, :paused] do
    queue
    |> Queue.status_changeset(new_status)
    |> Repo.update()
  end

  @doc """
  Pauses a queue (sets status to :paused).
  """
  def pause_queue(%Queue{} = queue) do
    update_queue_status(queue, :paused)
  end

  @doc """
  Activates a queue (sets status to :active).
  """
  def activate_queue(%Queue{} = queue) do
    update_queue_status(queue, :active)
  end

  @doc """
  Deactivates a queue (sets status to :inactive).
  """
  def deactivate_queue(%Queue{} = queue) do
    update_queue_status(queue, :inactive)
  end

  @doc """
  Soft deletes a queue and all associated tickets.
  Uses a transaction to ensure data consistency.
  """
  def delete_queue(%Queue{} = queue) do
    Repo.transaction(fn ->
      # First, mark all tickets as cancelled
      Repo.update_all(from(t in Ticket, where: t.queue_id == ^queue.id and t.status in [:waiting, :called]),
        set: [status: :cancelled, updated_at: DateTime.utc_now()]
      )

      # Then soft delete the queue
      queue
      |> Queue.delete_changeset()
      |> Repo.update!()
    end)
  end

  @doc """
  Permanently deletes a queue and all associated tickets.
  ⚠️  Use with extreme caution - this cannot be undone.
  """
  def hard_delete_queue(%Queue{} = queue) do
    Repo.transaction(fn ->
      # Delete associated tickets first
      Repo.delete_all(from(t in Ticket, where: t.queue_id == ^queue.id))

      # Then delete the queue
      Repo.delete!(queue)
    end)
  end

  @doc """
  Soft deletes all queues for a given organization.
  Used for org cleanup operations.
  """
  def delete_all_queues_for_org(org_id) when is_integer(org_id) do
    Repo.transaction(fn ->
      # Get all active queues for the org
      queue_ids =
        Queue
        |> Queue.by_org(org_id)
        |> Queue.not_deleted()
        |> select([q], q.id)
        |> Repo.all()

      # Cancel all waiting/called tickets
      Repo.update_all(from(t in Ticket, where: t.queue_id in ^queue_ids and t.status in [:waiting, :called]),
        set: [status: :cancelled, updated_at: DateTime.utc_now()]
      )

      # Soft delete all queues
      now = DateTime.utc_now()

      Queue
      |> Queue.by_org(org_id)
      |> Queue.not_deleted()
      |> Repo.update_all(
        set: [
          deleted_at: now,
          status: :inactive,
          is_active: false,
          updated_at: now
        ]
      )
    end)
  end

  @doc """
  Returns a changeset for a queue, useful for form building.
  Uses the appropriate changeset based on whether it's a new or existing queue.
  """
  def change_queue(queue, attrs \\ %{})
  def change_queue(%Queue{id: nil} = queue, attrs), do: Queue.create_changeset(queue, attrs)
  def change_queue(%Queue{} = queue, attrs), do: Queue.update_changeset(queue, attrs)

  @doc """
  Adds a new ticket to a queue, generating the next sequential ticket number.
  Uses a database transaction with proper locking to ensure atomicity and prevent race conditions.
  Includes validation for daily limits and queue operational status.

  ## Examples
      iex> add_ticket_to_queue(queue, %{customer_name: "John Doe"})
      {:ok, %Ticket{ticket_number: 1}}

      iex> add_ticket_to_queue(inactive_queue, %{customer_name: "Jane Doe"})
      {:error, :queue_not_operational}
  """
  def add_ticket_to_queue(%Queue{} = queue, attrs) when is_map(attrs) do
    # Pre-flight checks before transaction
    cond do
      not Queue.operational?(queue) ->
        {:error, :queue_not_operational}

      Queue.daily_limit_reached?(queue) ->
        {:error, :daily_limit_reached}

      true ->
        create_ticket_transaction(queue, attrs)
    end
  end

  defp create_ticket_transaction(%Queue{} = queue, attrs) do
    Repo.transaction(fn ->
      # Lock the queue row to prevent race conditions on ticket number generation
      locked_queue =
        Queue
        |> where([q], q.id == ^queue.id)
        |> lock("FOR UPDATE")
        |> Repo.one!()

      # Double-check operational status after lock
      unless Queue.operational?(locked_queue) do
        Repo.rollback(:queue_not_operational)
      end

      next_ticket_number = locked_queue.current_ticket_number + 1

      # Update the queue's ticket counter using the specialized changeset
      case locked_queue |> Queue.counter_changeset(%{current_ticket_number: next_ticket_number}) |> Repo.update() do
        {:ok, updated_queue} ->
          # Create the ticket with the newly generated number
          case Tickets.create_ticket_with_number(attrs, updated_queue, next_ticket_number) do
            {:ok, ticket} -> ticket
            {:error, reason} -> Repo.rollback(reason)
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Calls the next waiting ticket in the queue and updates the queue's last served number.
  Uses a database transaction with proper locking to ensure atomicity.
  Includes validation for queue operational status.

  Returns:
  - `{:ok, ticket}` - Successfully called the next ticket
  - `{:error, :no_waiting_tickets}` - No tickets are currently waiting
  - `{:error, :queue_not_operational}` - Queue is not in an operational state
  - `{:error, reason}` - Other database or validation errors
  """
  def call_next_ticket(%Queue{} = queue) do
    if Queue.operational?(queue) do
      call_next_ticket_transaction(queue)
    else
      {:error, :queue_not_operational}
    end
  end

  defp call_next_ticket_transaction(%Queue{} = queue) do
    Repo.transaction(fn ->
      # Lock the queue to prevent concurrent modifications
      locked_queue =
        Queue
        |> where([q], q.id == ^queue.id)
        |> lock("FOR UPDATE")
        |> Repo.one!()

      # Find the next waiting ticket (ordered by ticket number for proper FIFO)
      next_waiting_ticket =
        Repo.one(
          from(t in Ticket,
            where: t.queue_id == ^locked_queue.id and t.status == :waiting,
            order_by: [asc: t.ticket_number],
            limit: 1
          )
        )

      case next_waiting_ticket do
        nil ->
          Repo.rollback(:no_waiting_tickets)

        ticket ->
          # Update the ticket's status to "called"
          case Tickets.call_ticket(ticket) do
            {:ok, updated_ticket} ->
              # Update the queue's last served ticket number using specialized changeset
              case locked_queue
                   |> Queue.counter_changeset(%{last_served_ticket_number: updated_ticket.ticket_number})
                   |> Repo.update() do
                {:ok, _} -> updated_ticket
                {:error, reason} -> Repo.rollback(reason)
              end

            {:error, reason} ->
              Repo.rollback(reason)
          end
      end
    end)
  end

  @doc """
  Gets enhanced queue statistics including total tickets, waiting tickets, served tickets, and performance metrics.
  Uses the schema helper function and adds additional calculated metrics.

  ## Examples
      iex> get_queue_stats(queue)
      %{
        total: 10,
        waiting: 3,
        served: 7,
        current_number: 10,
        tickets_in_queue: 3,
        daily_limit_reached: false,
        operational: true
      }
  """
  def get_queue_stats(%Queue{} = queue) do
    ticket_stats =
      from(t in Ticket,
        where: t.queue_id == ^queue.id,
        group_by: t.status,
        select: {t.status, count(t.id)}
      )
      |> Repo.all()
      |> Map.new()

    base_stats = %{
      total: Enum.reduce(ticket_stats, 0, fn {_, count}, acc -> acc + count end),
      waiting: Map.get(ticket_stats, :waiting, 0),
      called: Map.get(ticket_stats, :called, 0),
      serving: Map.get(ticket_stats, :serving, 0),
      completed: Map.get(ticket_stats, :completed, 0),
      missed: Map.get(ticket_stats, :missed, 0),
      cancelled: Map.get(ticket_stats, :cancelled, 0),
      current_number: queue.current_ticket_number,
      last_served: queue.last_served_ticket_number
    }

    # Add calculated metrics using schema helper functions
    Map.merge(base_stats, %{
      tickets_in_queue: Queue.tickets_in_queue(queue),
      daily_limit_reached: Queue.daily_limit_reached?(queue),
      operational: Queue.operational?(queue),
      served_today: base_stats.completed + base_stats.serving
    })
  end

  @doc """
  Gets all waiting tickets for a queue, ordered by ticket number.
  """
  def list_waiting_tickets(%Queue{} = queue) do
    Repo.all(from(t in Ticket, where: t.queue_id == ^queue.id and t.status == :waiting, order_by: [asc: t.ticket_number]))
  end

  @doc """
  Gets the current queue position for a specific ticket number.
  Returns nil if ticket is not waiting or doesn't exist.
  """
  def get_queue_position(queue_id, ticket_number) when is_integer(queue_id) and is_integer(ticket_number) do
    from(t in Ticket,
      where:
        t.queue_id == ^queue_id and
          t.status == :waiting and
          t.ticket_number < ^ticket_number,
      select: count(t.id)
    )
    |> Repo.one()
    |> case do
      # Position is count + 1
      count when is_integer(count) -> count + 1
      _ -> nil
    end
  end

  @doc """
  Performs daily reset for queues that have daily_reset enabled.
  Should be called by a scheduled job (e.g., daily cron job).

  Returns the number of queues that were reset.
  """
  def perform_daily_reset do
    queues_to_reset =
      Queue
      |> Queue.active_queues()
      |> where([q], q.daily_reset == true)
      |> Repo.all()

    reset_count =
      Enum.reduce(queues_to_reset, 0, fn queue, count ->
        case reset_queue_counters(queue) do
          {:ok, _} -> count + 1
          {:error, _} -> count
        end
      end)

    {:ok, reset_count}
  end

  @doc """
  Resets a queue's ticket counters to 0.
  Also cancels any remaining waiting or called tickets.
  """
  def reset_queue_counters(%Queue{} = queue) do
    Repo.transaction(fn ->
      # Cancel all waiting and called tickets
      Repo.update_all(from(t in Ticket, where: t.queue_id == ^queue.id and t.status in [:waiting, :called]),
        set: [status: :cancelled, updated_at: DateTime.utc_now()]
      )

      # Reset the queue counters
      queue
      |> Queue.daily_reset_changeset()
      |> Repo.update!()
    end)
  end

  @doc """
  Gets queues that are approaching their daily limit (80% or more).
  Useful for alerts and monitoring.
  """
  def list_queues_near_limit(org_id) when is_integer(org_id) do
    Queue
    |> Queue.by_org(org_id)
    |> Queue.active_queues()
    |> where([q], not is_nil(q.max_tickets_per_day))
    |> Repo.all()
    |> Enum.filter(fn queue ->
      percentage = queue.current_ticket_number / queue.max_tickets_per_day
      percentage >= 0.8
    end)
  end

  @doc """
  Gets comprehensive queue analytics for reporting.
  """
  def get_queue_analytics(queue_id, date_range \\ :today) when is_integer(queue_id) do
    base_query = from(t in Ticket, where: t.queue_id == ^queue_id)

    date_filtered_query =
      case date_range do
        :today ->
          today = Date.utc_today()
          where(base_query, [t], fragment("DATE(?)", t.inserted_at) == ^today)

        :week ->
          week_ago = Date.add(Date.utc_today(), -7)
          where(base_query, [t], fragment("DATE(?)", t.inserted_at) >= ^week_ago)

        :month ->
          month_ago = Date.add(Date.utc_today(), -30)
          where(base_query, [t], fragment("DATE(?)", t.inserted_at) >= ^month_ago)

        _ ->
          base_query
      end

    # Get ticket distribution by status
    status_stats =
      date_filtered_query
      |> group_by([t], t.status)
      |> select([t], {t.status, count(t.id)})
      |> Repo.all()
      |> Map.new()

    # Get hourly ticket creation pattern
    hourly_pattern =
      date_filtered_query
      |> group_by([t], fragment("EXTRACT(hour FROM ?)", t.inserted_at))
      |> select([t], {fragment("EXTRACT(hour FROM ?)", t.inserted_at), count(t.id)})
      |> Repo.all()
      |> Map.new()

    %{
      period: date_range,
      status_distribution: status_stats,
      hourly_pattern: hourly_pattern,
      total_tickets: Enum.reduce(status_stats, 0, fn {_, count}, acc -> acc + count end),
      completion_rate: calculate_completion_rate(status_stats)
    }
  end

  # Private helper functions

  defp calculate_completion_rate(status_stats) do
    completed = Map.get(status_stats, :completed, 0)
    total_processed = completed + Map.get(status_stats, :missed, 0) + Map.get(status_stats, :cancelled, 0)

    if total_processed > 0 do
      Float.round(completed / total_processed * 100, 2)
    else
      0.0
    end
  end
end
