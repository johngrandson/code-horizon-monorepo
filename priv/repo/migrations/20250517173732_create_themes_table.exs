defmodule PetalPro.Repo.Migrations.CreateThemesTable do
  use Ecto.Migration

  def change do
    create table(:themes) do
      add :name, :string, null: false
      add :description, :string

      # Main branding colors
      add :primary_color, :string
      add :secondary_color, :string
      add :accent_color, :string

      # Logo and brand assets
      add :logo_url, :string
      add :favicon_url, :string
      add :hero_image_url, :string

      # UI settings
      add :font_family, :string
      add :border_radius, :string

      # Navigation customization
      add :navbar_style, :string
      add :sidebar_style, :string

      # CSS and JS overrides
      add :custom_css, :text
      add :custom_js, :text

      # Theme availability flags
      add :is_default, :boolean, default: false
      add :is_public, :boolean, default: false

      # Misc configuration as JSON
      add :settings, :map, default: %{}

      # Self-reference for inherited themes
      add :parent_theme_id, references(:themes, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:themes, [:name])
    create index(:themes, [:is_default])
    create index(:themes, [:parent_theme_id])

    # Add theme_id to orgs table
    alter table(:orgs) do
      add :theme_id, references(:themes, on_delete: :nilify_all)
    end
  end
end
