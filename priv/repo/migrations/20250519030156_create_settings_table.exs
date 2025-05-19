defmodule PetalPro.Repo.Migrations.CreateSettingsTable do
  use Ecto.Migration

  def change do
    # Create the table with auto-incrementing ID
    create table(:settings) do
      # Setting identifier (e.g., "max_orgs_free_user")
      add :key, :string, size: 255, null: false

      # Setting value (stored as JSONB for flexibility)
      add :value, :map, null: false

      # Human-readable description
      add :description, :text

      # Whether this setting is publicly accessible
      add :is_public, :boolean, default: false, null: false

      # Timestamps with timezone
      timestamps(type: :utc_datetime)
    end

    # Indexes
    create unique_index(:settings, [:key], name: "settings_key_index")

    # For querying public settings
    create index(:settings, [:is_public],
             name: "settings_is_public_index",
             where: "is_public = true"
           )
  end
end
