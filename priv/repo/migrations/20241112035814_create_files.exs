defmodule PetalPro.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :url, :string, null: false
      add :name, :string, null: false
      add :archived, :boolean, null: false

      add :author_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:files, [:author_id])
  end
end
