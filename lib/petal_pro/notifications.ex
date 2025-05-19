defmodule PetalPro.Notifications do
  @moduledoc """
  The Notifications context is responsible for managing user notifications - both in-app and email.

  As of initial release, we've implemented one user notification flow for your reference: Sending an org invitation,
  and the inverse - deletion of that notification if the invitation is deleted.

  To implement other types of notifications for your use case, try following this general pattern:

  1. Add the new type to @notification_types in the UserNotification schema.
  2. In notifications_components.ex, add a new function clause for rendering this notification type with `notification_item/1`.
  3. Extend user_notification_attrs.ex, this is where we're housing attr definition functions by notification type/action.
  4. Define a new function in the Notifications context to handle your event + notification creation flow. We house these under
  the Notifications context to avoid some_entity + user_notification transactions being scattered across several contexts.
  """
  use PetalProWeb, :verified_routes

  import Ecto.Query, warn: false

  alias PetalPro.Accounts.User
  alias PetalPro.Notifications.UserNotification
  alias PetalPro.Repo

  @doc """
  Returns the topic for a user's notifications.
  """
  def user_notifications_topic(user_id) when not is_nil(user_id), do: "user_notifications:#{user_id}"

  @doc """
  Broadcasts the `notifications_updated` event to the user's notifications topic.
  """
  def broadcast_user_notification(%UserNotification{
        id: notification_id,
        type: notification_type,
        recipient_id: recipient_id
      }) do
    PetalProWeb.Endpoint.broadcast(
      user_notifications_topic(recipient_id),
      "notifications_updated",
      %{id: notification_id, type: notification_type}
    )
  end

  def broadcast_user_notification(user_id) when not is_nil(user_id) do
    PetalProWeb.Endpoint.broadcast(
      user_notifications_topic(user_id),
      "notifications_updated",
      %{}
    )
  end

  def create_user_notification(attrs) do
    %UserNotification{}
    |> UserNotification.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_notification_multi(multi, attrs) do
    user_notification_cs = UserNotification.changeset(%UserNotification{}, attrs)
    Ecto.Multi.insert(multi, :user_notification, user_notification_cs)
  end

  def get_user_notification!(id) do
    Repo.get!(UserNotification, id)
  end

  @doc """
  For the given user, sets all unread notifications `:read_at` field to the value of `DateTime.utc_now/0`.
  """
  def mark_all_user_notifications_as_read(%User{id: user_id}) do
    Repo.update_all(
      from(
        un in UserNotification,
        where: un.recipient_id == ^user_id and is_nil(un.read_at)
      ),
      set: [read_at: DateTime.utc_now()]
    )
  end

  @doc """
  For the given user, sets the `:read_at` field of one notification to the value of `DateTime.utc_now/0`.
  If the user is not authorized to read the notification, returns `{:error, :unauthorized}`.
  """
  def mark_user_notification_as_read(
        %User{id: authorized_user_id},
        %UserNotification{recipient_id: authorized_user_id} = notification
      ) do
    notification
    |> UserNotification.mark_read_changeset()
    |> Repo.update()
    |> case do
      {:ok, notification} ->
        broadcast_user_notification(notification.recipient_id)
        {:ok, notification}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def mark_user_notification_as_read(_, _), do: {:error, :unauthorized}

  @doc """
  Returns the total number of notifications for a user.
  """
  def count_user_notifications(%User{id: user_id}) do
    query = from(un in UserNotification, where: un.recipient_id == ^user_id)
    Repo.aggregate(query, :count, :id) || 0
  end

  @doc """
  Returns the number of unread notifications for a user.
  """
  def count_unread_user_notifications(%User{id: user_id}) do
    query = from(un in UserNotification, where: un.recipient_id == ^user_id and is_nil(un.read_at))
    Repo.aggregate(query, :count, :id) || 0
  end

  @doc """
  Reads unread notifications for a user whose `:read_path` is the same as the given request path.
  """
  def read_unread_user_notifications_for_path(%User{} = user, request_path) do
    UserNotification
    |> where([un], un.recipient_id == ^user.id)
    |> where([un], is_nil(un.read_at))
    |> where([un], un.read_path == ^request_path)
    |> Repo.update_all(set: [read_at: DateTime.utc_now()])
    |> case do
      {updated_count, _} = result_tuple when updated_count > 0 ->
        broadcast_user_notification(user.id)
        result_tuple

      result_tuple ->
        result_tuple
    end
  end

  @doc """
  Lists the notifications for a user. Accepts the following options:
    * `:unread_only` - `:boolean` - only return unread notifications
    * `:limit` - `:integer` - limit the number of notifications returned
  """
  def list_user_notifications(user, opts \\ [])

  def list_user_notifications(%User{} = user, opts) do
    user
    |> user_notifications_query(opts)
    |> Repo.all()
  end

  def list_user_notifications(_, _), do: []

  @doc """
  Query for listing a user's notifications in the notification drawer.
  """
  def user_notifications_query(%User{id: user_id}, opts \\ []) do
    query =
      from(un in UserNotification,
        where: un.recipient_id == ^user_id,
        order_by: [desc: un.inserted_at],
        preload: [:sender, :org]
      )

    apply_user_notifications_query_opts(query, opts)
  end

  defp apply_user_notifications_query_opts(query, []), do: query

  defp apply_user_notifications_query_opts(query, opts) do
    Enum.reduce(opts, query, &apply_user_notifications_query_opt/2)
  end

  defp apply_user_notifications_query_opt({:unread_only, true}, query), do: where(query, [un], is_nil(un.read_at))
  defp apply_user_notifications_query_opt({:limit, limit}, query) when is_integer(limit), do: limit(query, ^limit)
  defp apply_user_notifications_query_opt(_, query), do: query
end
