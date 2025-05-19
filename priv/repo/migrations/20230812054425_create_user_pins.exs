defmodule PetalPro.Repo.Migrations.CreateUserPins do
  use Ecto.Migration

  def change do
    create table(:users_pins) do
      add :hashed_pin, :binary, null: false
      add :attempts, :integer, null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:users_pins, [:user_id])
  end
end
