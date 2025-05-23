defmodule PetalPro.Events.Modules.Notifications.UserNotification do
  @moduledoc """
  The UserNotification schema represents a notification sent to a user.

  It may have been triggered/sent by a specific user, but the variety of notifications
  one might implement means it may just be triggered by the app, so `:sender_id` is optional.

  The same goes for `:org_id`. Not all notifications will be related to an org,
  but being able to preload that data when they are is very helpful at render-time.
  """
  use PetalPro.Schema

  alias PetalPro.Accounts.User
  alias PetalPro.Orgs.Org

  @notification_types [:invited_to_org]

  def types, do: @notification_types

  schema "user_notifications" do
    field :type, Ecto.Enum, values: @notification_types
    field :message, :string

    field :read_at, :utc_datetime

    # optional to cater for broad use cases, but :read_path is
    # important for most notifications as it's queried for during on_mount/4
    # so we can mark a notification read when loading the relevant page
    field :read_path, :string

    belongs_to :recipient, User
    belongs_to :sender, User
    belongs_to :org, Org

    timestamps()
  end

  def changeset(un, attrs) do
    un
    |> cast(attrs, [:type, :read_path, :read_at, :message, :recipient_id, :sender_id, :org_id])
    |> validate_required([:type, :recipient_id])
  end

  def mark_read_changeset(un, attrs \\ %{read_at: DateTime.utc_now()}) do
    un
    |> cast(attrs, [:read_at])
    |> validate_required([:read_at])
  end
end
