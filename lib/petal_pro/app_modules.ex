defmodule PetalPro.AppModules do
  @moduledoc """
  The Modules context handles application module management and subscriptions.

  This context provides functions to:
  - Manage module registrations
  - Handle org module subscriptions
  - Check module access permissions
  - Initialize and cleanup module data for orgs
  """

  import Ecto.Query, warn: false

  alias PetalPro.AppModules.AppModule
  alias PetalPro.AppModules.Subscription
  alias PetalPro.Repo

  @doc """
  Returns the list of app modules with optional filtering.

  ## Examples

      iex> list_app_modules()
      [%AppModule{}, ...]

      iex> list_app_modules(status: :active)
      [%AppModule{status: :active}, ...]
  """
  def list_app_modules(filters \\ []) do
    AppModule
    |> apply_filters(filters)
    |> order_by([m], asc: m.name)
    |> Repo.all()
  end

  @doc """
  Gets a single app module by ID.

  Raises `Ecto.NoResultsError` if the AppModule does not exist.

  ## Examples

      iex> get_app_module!(123)
      %AppModule{}

      iex> get_app_module!(456)
      ** (Ecto.NoResultsError)
  """
  def get_app_module!(id), do: Repo.get!(AppModule, id)

  @doc """
  Gets a single app module by code.

  ## Examples

      iex> get_app_module_by_code("crm")
      %AppModule{}

      iex> get_app_module_by_code("nonexistent")
      nil
  """
  def get_app_module_by_code(code) when is_binary(code) do
    Repo.get_by(AppModule, code: code)
  end

  @doc """
  Gets a single app module by code, raising if not found.

  ## Examples

      iex> get_app_module_by_code!("crm")
      %AppModule{}

      iex> get_app_module_by_code!("nonexistent")
      ** (Ecto.NoResultsError)
  """
  def get_app_module_by_code!(code) when is_binary(code) do
    Repo.get_by!(AppModule, code: code)
  end

  @doc """
  Creates an app module.

  ## Examples

      iex> create_app_module(%{code: "crm", name: "CRM"})
      {:ok, %AppModule{}}

      iex> create_app_module(%{code: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_app_module(attrs \\ %{}) do
    result =
      %AppModule{}
      |> AppModule.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, app_module} ->
        broadcast_app_module_event(app_module, :created)
        {:ok, app_module}

      error ->
        error
    end
  end

  @doc """
  Updates an app module.

  ## Examples

      iex> update_app_module(app_module, %{name: "Updated Name"})
      {:ok, %AppModule{}}

      iex> update_app_module(app_module, %{code: nil})
      {:error, %Ecto.Changeset{}}
  """
  def update_app_module(%AppModule{} = app_module, attrs) do
    result =
      app_module
      |> AppModule.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_module} ->
        broadcast_app_module_event(updated_module, :updated)
        {:ok, updated_module}

      error ->
        error
    end
  end

  @doc """
  Deletes an app module.

  ## Examples

      iex> delete_app_module(app_module)
      {:ok, %AppModule{}}

      iex> delete_app_module(app_module)
      {:error, %Ecto.Changeset{}}
  """
  def delete_app_module(%AppModule{} = app_module) do
    result = Repo.delete(app_module)

    case result do
      {:ok, deleted_module} ->
        broadcast_app_module_event(deleted_module, :deleted)
        {:ok, deleted_module}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app module changes.

  ## Examples

      iex> change_app_module(app_module)
      %Ecto.Changeset{data: %AppModule{}}
  """
  def change_app_module(%AppModule{} = app_module, attrs \\ %{}) do
    AppModule.changeset(app_module, attrs)
  end

  # Private functions

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:status, status} | rest]) when is_atom(status) do
    query
    |> where([m], m.status == ^status)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:is_publicly_visible, visible} | rest]) when is_boolean(visible) do
    query
    |> where([m], m.is_publicly_visible == ^visible)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:is_white_label_ready, ready} | rest]) when is_boolean(ready) do
    query
    |> where([m], m.is_white_label_ready == ^ready)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:search, term} | rest]) when is_binary(term) do
    term = "%#{term}%"

    query
    |> where([m], ilike(m.name, ^term) or ilike(m.description, ^term) or ilike(m.code, ^term))
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_unknown | rest]) do
    apply_filters(query, rest)
  end

  defp broadcast_app_module_event(app_module, event) do
    Phoenix.PubSub.broadcast(
      PetalPro.PubSub,
      "app_modules",
      {event, app_module}
    )

    # Log the event for audit purposes
    PetalPro.Logs.log_async("app_module_#{event}", %{
      module_id: app_module.id,
      module_code: app_module.code,
      module_name: app_module.name
    })
  end

  @doc """
  Gets a specific module subscription for an org.
  """
  def get_org_app_module_subscription(org_id, module_code) do
    Subscription
    |> where([s], s.org_id == ^org_id and s.module_code == ^module_code)
    |> Repo.one()
  end
end
