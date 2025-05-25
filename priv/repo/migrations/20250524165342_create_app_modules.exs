defmodule PetalPro.Repo.Migrations.CreateAppModules do
  use Ecto.Migration

  def change do
    create table(:app_modules) do
      add :code, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :version, :string, null: false
      add :dependencies, :jsonb, default: "[]"
      add :status, :string, null: false, default: "inactive"
      add :price_id, :string
      add :is_white_label_ready, :boolean, default: false
      add :is_publicly_visible, :boolean, default: false
      add :setup_function, :text
      add :cleanup_function, :text
      add :routes_definition, :jsonb, default: "{}"

      timestamps()
    end

    create unique_index(:app_modules, [:code])
  end
end
