defmodule PetalPro.Repo.Migrations.SetDefaultNonNullRole do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :role, :string, null: false
    end
  end

  def down do
    alter table(:users) do
      modify :role, :string, null: true
    end
  end
end
