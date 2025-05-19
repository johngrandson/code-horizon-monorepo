defmodule PetalPro.WhiteLabel.Theme do
  @moduledoc """
  Schema representing a customizable theme for orgs in the white-label system.

  Themes store visual preferences, branding assets, and UI customizations
  that can be applied to an org's interface.
  """
  use PetalPro.Schema

  import Ecto.Changeset

  alias PetalPro.Orgs.Org

  # Emerald 600 (Tailwind)
  @primary_color_default "#10b981"
  # Blue 500 (Tailwind)
  @secondary_color_default "#3b82f6"

  typed_schema "themes" do
    field :name, :string
    field :description, :string

    # Main branding colors
    field :primary_color, :string, default: @primary_color_default
    field :secondary_color, :string, default: @secondary_color_default
    field :accent_color, :string

    # Logo and brand assets
    field :logo_url, :string
    field :favicon_url, :string
    field :hero_image_url, :string

    # UI settings
    field :font_family, :string
    field :border_radius, :string

    # Navigation customization
    field :navbar_style, Ecto.Enum, values: [:standard, :minimal, :expanded], default: :standard
    field :sidebar_style, Ecto.Enum, values: [:standard, :compact, :hidden], default: :standard

    # CSS and JS overrides
    field :custom_css, :string
    field :custom_js, :string

    # Theme availability flags
    field :is_default, :boolean, default: false
    field :is_public, :boolean, default: false

    # Misc configuration as JSON
    field :settings, :map, default: %{}

    # Relationships
    has_many :orgs, Org

    # If themes can be inheritable/extendable
    belongs_to :parent_theme, __MODULE__, foreign_key: :parent_theme_id

    timestamps()
  end

  @doc """
  Changeset for creating a new theme.
  """
  def create_changeset(theme, attrs) do
    theme
    |> cast(attrs, [
      :name,
      :description,
      :primary_color,
      :secondary_color,
      :accent_color,
      :logo_url,
      :favicon_url,
      :hero_image_url,
      :font_family,
      :border_radius,
      :navbar_style,
      :sidebar_style,
      :custom_css,
      :custom_js,
      :is_default,
      :is_public,
      :settings,
      :parent_theme_id
    ])
    |> validate_required([:name])
    |> validate_color_format(:primary_color)
    |> validate_color_format(:secondary_color)
    |> validate_color_format(:accent_color)
    |> validate_color_contrast()
    |> unique_constraint(:name)
    |> foreign_key_constraint(:parent_theme_id)
  end

  @doc """
  Changeset for updating an existing theme.
  """
  def update_changeset(theme, attrs) do
    create_changeset(theme, attrs)
  end

  @doc """
  Returns the default theme configuration.
  This is useful as a fallback when no custom theme is available.
  """
  def default_theme do
    %{
      primary_color: @primary_color_default,
      secondary_color: @secondary_color_default,
      navbar_style: :standard,
      sidebar_style: :standard,
      font_family: "Inter, system-ui, sans-serif",
      # equivalent to Tailwind's rounded-md
      border_radius: "0.375rem",
      settings: %{}
    }
  end

  # Private validation functions

  # Validates that colors are in valid hex format
  defp validate_color_format(changeset, field) do
    validate_format(changeset, field, ~r/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/,
      message: "must be a valid hex color (e.g. #FF5500)"
    )
  end

  # Validates that primary and secondary colors have sufficient contrast
  # This helps ensure accessibility standards
  defp validate_color_contrast(changeset) do
    # A more sophisticated implementation would calculate actual contrast ratios
    # For now, we'll use a simplified placeholder
    changeset
  end
end
