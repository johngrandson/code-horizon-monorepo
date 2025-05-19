defmodule PetalPro.WhiteLabel.Themes do
  @moduledoc """
  Context for managing white-label themes in the multi-tenant system.

  This module provides functions for creating, updating, and applying themes
  to orgs, enabling white-label customization of the UI.
  """

  import Ecto.Query, warn: false

  alias PetalPro.Orgs.Org
  alias PetalPro.Repo
  alias PetalPro.WhiteLabel.Theme

  @doc """
  Returns the theme for the specified org.
  If the org doesn't have a theme assigned, returns the default theme.

  ## Examples

      iex> get_theme_for_org(org_id)
      %Theme{}

      iex> get_theme_for_org(123)
      %{primary_color: "#10b981", ...} # Default theme map
  """
  def get_theme_for_org(org_id) do
    query =
      from t in Org,
        where: t.id == ^org_id,
        select: t.theme_id

    case Repo.one(query) do
      nil ->
        get_default_theme()

      theme_id when is_binary(theme_id) ->
        Repo.get(Theme, theme_id) || get_default_theme()

      _ ->
        get_default_theme()
    end
  end

  @doc """
  Lists all available themes.

  ## Options

    * `:public_only` - When true, only returns themes marked as public
    * `:include_default` - When true, includes the default theme in the results

  ## Examples

      iex> list_themes()
      [%Theme{}, ...]

      iex> list_themes(public_only: true)
      [%Theme{}, ...]
  """
  def list_themes(opts \\ []) do
    public_only = Keyword.get(opts, :public_only, false)

    query = from(t in Theme)

    query =
      if public_only do
        from t in query, where: t.is_public == true
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets a single theme by ID.

  Raises `Ecto.NoResultsError` if the theme does not exist.

  ## Examples

      iex> get_theme!(123)
      %Theme{}

      iex> get_theme!(456)
      ** (Ecto.NoResultsError)
  """
  def get_theme!(id), do: Repo.get!(Theme, id)

  @doc """
  Gets a theme by ID, returning nil if not found.

  ## Examples

      iex> get_theme(123)
      %Theme{}

      iex> get_theme(456)
      nil
  """
  def get_theme(id), do: Repo.get(Theme, id)

  @doc """
  Gets the default theme.
  This is either the theme marked as default in the database,
  or a fallback default theme if none is set.

  ## Examples

      iex> get_default_theme()
      %Theme{}
  """
  def get_default_theme do
    query = from t in Theme, where: t.is_default == true, limit: 1

    case Repo.one(query) do
      nil ->
        # Return the hardcoded default
        Theme.default_theme()

      theme ->
        theme
    end
  end

  @doc """
  Creates a theme.

  ## Examples

      iex> create_theme(%{name: "Corporate Blue"})
      {:ok, %Theme{}}

      iex> create_theme(%{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_theme(attrs \\ %{}) do
    %Theme{}
    |> Theme.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a theme.

  ## Examples

      iex> update_theme(theme, %{primary_color: "#FF0000"})
      {:ok, %Theme{}}

      iex> update_theme(theme, %{primary_color: "invalid"})
      {:error, %Ecto.Changeset{}}
  """
  def update_theme(%Theme{} = theme, attrs) do
    theme
    |> Theme.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a theme.

  ## Examples

      iex> delete_theme(theme)
      {:ok, %Theme{}}

      iex> delete_theme(theme)
      {:error, %Ecto.Changeset{}}
  """
  def delete_theme(%Theme{} = theme) do
    Repo.delete(theme)
  end

  @doc """
  Assigns a theme to an org.

  ## Examples

      iex> assign_theme_to_org(org, theme)
      {:ok, %Org{}}

      iex> assign_theme_to_org(org, nil)
      {:error, %Ecto.Changeset{}}
  """
  def assign_theme_to_org(%Org{} = org, %Theme{} = theme) do
    org
    |> Org.update_changeset(%{theme_id: theme.id})
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking theme changes.

  ## Examples

      iex> change_theme(theme)
      %Ecto.Changeset{data: %Theme{}}
  """
  def change_theme(%Theme{} = theme, attrs \\ %{}) do
    Theme.create_changeset(theme, attrs)
  end

  @doc """
  Clones an existing theme with a new name.
  Useful for creating derived themes.

  ## Examples

      iex> clone_theme(source_theme, "Corporate Blue - Dark")
      {:ok, %Theme{}}
  """
  def clone_theme(%Theme{} = source_theme, new_name) do
    # Get all fields from source theme except id, inserted_at, updated_at
    attrs =
      source_theme
      |> Map.from_struct()
      |> Map.drop([:__meta__, :id, :inserted_at, :updated_at, :orgs])
      |> Map.put(:name, new_name)
      |> Map.put(:parent_theme_id, source_theme.id)

    create_theme(attrs)
  end
end
