defmodule PetalPro.Repo.Migrations.AddTypeToSettings do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Add the type column with default value "string"
    alter table(:settings) do
      add :type, :string, default: "string", null: false
    end

    # Create an index on the type column
    create index(:settings, [:type])

    # Update existing records based on their value types
    execute """
    UPDATE settings
    SET type = CASE
      WHEN jsonb_typeof(value->'value') = 'boolean' THEN 'boolean'
      WHEN jsonb_typeof(value->'value') = 'number' THEN 'number'
      WHEN jsonb_typeof(value->'value') = 'object' THEN 'map'
      WHEN jsonb_typeof(value->'value') = 'array' THEN 'list'
      ELSE 'string'
    END
    WHERE value ? 'value';
    """

    # Handle direct values without "value" wrapper
    execute """
    UPDATE settings
    SET type = CASE
      WHEN jsonb_typeof(value) = 'boolean' THEN 'boolean'
      WHEN jsonb_typeof(value) = 'number' THEN 'number'
      WHEN jsonb_typeof(value) = 'object' AND NOT value ? 'value' THEN 'map'
      WHEN jsonb_typeof(value) = 'array' THEN 'list'
      ELSE 'string'
    END
    WHERE NOT value ? 'value';
    """
  end

  def down do
    # Remove the type column
    alter table(:settings) do
      remove :type
    end
  end
end
