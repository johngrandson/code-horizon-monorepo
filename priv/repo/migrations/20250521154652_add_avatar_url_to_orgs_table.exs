defmodule PetalPro.Repo.Migrations.AddAvatarUrlToOrgsTable do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :avatar_url, :string
    end
  end
end
