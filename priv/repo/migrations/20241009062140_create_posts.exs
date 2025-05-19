defmodule PetalPro.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :category, :string
      add :title, :string, null: false
      add :slug, :string, null: false
      add :cover, :text
      add :cover_caption, :string
      add :summary, :text
      add :content, :text
      add :duration, :integer

      add :published_category, :string
      add :published_title, :string
      add :published_slug, :string
      add :published_cover, :text
      add :published_cover_caption, :string
      add :published_summary, :text
      add :published_content, :text
      add :published_duration, :integer

      add :last_published, :naive_datetime
      add :go_live, :utc_datetime

      add :author_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end
  end
end
