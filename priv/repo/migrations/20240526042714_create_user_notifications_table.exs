defmodule PetalPro.Repo.Migrations.CreateUserNotificationsTable do
  use Ecto.Migration

  def change do
    create table(:user_notifications) do
      add :type, :string, null: false

      add :message, :text
      add :read_at, :utc_datetime

      # nullable to cater for broad use cases, but :read_path is
      # important for most notifications as it's queried for during on_mount/4
      # so we can mark a notification read when loading the relevant page
      add :read_path, :string

      add :recipient_id, references(:users, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :delete_all)
      add :org_id, references(:orgs, on_delete: :delete_all)

      timestamps()
    end

    # all notifications for user
    create index(:user_notifications, [:recipient_id])

    # all unread_notifications for user
    create index(:user_notifications, [:recipient_id, :read_at])

    # maybe read notifications on mount with request_path
    create index(:user_notifications, [:recipient_id, :read_path, :read_at])
  end
end
