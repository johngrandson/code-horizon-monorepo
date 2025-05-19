defmodule PetalPro.Repo.Migrations.SetRoleValueToUsers do
  use Ecto.Migration

  def up do
    repo().query!("UPDATE users SET role = CASE WHEN is_admin THEN 'admin' ELSE 'user' END")
  end

  def down do
    repo().query!("UPDATE users SET is_admin = true WHERE role = 'admin'")
  end
end
