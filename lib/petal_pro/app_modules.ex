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
  alias PetalPro.AppModules.Registry
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

  @doc """
  Activates an app module by setting its status to active.

  ## Examples

      iex> activate_app_module(app_module)
      {:ok, %AppModule{status: :active}}
  """
  def activate_app_module(%AppModule{} = app_module) do
    update_app_module(app_module, %{status: :active})
  end

  @doc """
  Deactivates an app module by setting its status to inactive.

  ## Examples

      iex> deactivate_app_module(app_module)
      {:ok, %AppModule{status: :inactive}}
  """
  def deactivate_app_module(%AppModule{} = app_module) do
    update_app_module(app_module, %{status: :inactive})
  end

  @doc """
  Suspends an app module by setting its status to suspended.

  ## Examples

      iex> suspend_app_module(app_module)
      {:ok, %AppModule{status: :suspended}}
  """
  def suspend_app_module(%AppModule{} = app_module) do
    update_app_module(app_module, %{status: :suspended})
  end

  @doc """
  Lists active app modules that are available for use.

  ## Examples

      iex> list_available_modules()
      [%AppModule{status: :active}, ...]
  """
  def list_available_modules do
    AppModule
    |> where([m], m.status == :active)
    |> order_by([m], asc: m.name)
    |> Repo.all()
  end

  @doc """
  Lists modules that are publicly visible in the marketplace.

  ## Examples

      iex> list_public_modules()
      [%AppModule{is_publicly_visible: true}, ...]
  """
  def list_public_modules do
    AppModule
    |> where([m], m.is_publicly_visible == true and m.status == :active)
    |> order_by([m], asc: m.name)
    |> Repo.all()
  end

  @doc """
  Checks if a module has dependencies that are satisfied.

  ## Examples

      iex> dependencies_satisfied?(app_module, available_modules)
      true

      iex> dependencies_satisfied?(app_module, [])
      false
  """
  def dependencies_satisfied?(%AppModule{dependencies: []}, _available_modules), do: true

  def dependencies_satisfied?(%AppModule{dependencies: dependencies}, available_modules) do
    available_codes = MapSet.new(available_modules, & &1.code)
    required_codes = MapSet.new(dependencies)

    MapSet.subset?(required_codes, available_codes)
  end

  @doc """
  Gets modules that depend on the given module.

  ## Examples

      iex> get_dependent_modules("base_module")
      [%AppModule{dependencies: ["base_module"]}, ...]
  """
  def get_dependent_modules(module_code) when is_binary(module_code) do
    AppModule
    |> where([m], fragment("? = ANY(?)", ^module_code, m.dependencies))
    |> Repo.all()
  end

  @doc """
  Validates module dependencies and returns any circular dependencies.

  ## Examples

      iex> validate_dependencies([%AppModule{code: "a", dependencies: ["b"]}, %AppModule{code: "b", dependencies: ["a"]}])
      {:error, "Circular dependency detected: a -> b -> a"}

      iex> validate_dependencies([%AppModule{code: "a", dependencies: []}])
      :ok
  """
  def validate_dependencies(modules) when is_list(modules) do
    # Simple cycle detection using DFS
    # This could be enhanced with more sophisticated algorithms if needed
    module_map = Map.new(modules, &{&1.code, &1.dependencies})

    Enum.reduce_while(modules, :ok, fn module, _acc ->
      case detect_cycle(module.code, module_map, []) do
        {:cycle, path} -> {:halt, {:error, "Circular dependency detected: #{Enum.join(path, " -> ")}"}}
        :ok -> {:cont, :ok}
      end
    end)
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

  defp detect_cycle(module_code, module_map, visited) do
    if module_code in visited do
      {:cycle, visited ++ [module_code]}
    else
      dependencies = Map.get(module_map, module_code, [])
      new_visited = [module_code | visited]

      Enum.reduce_while(dependencies, :ok, fn dep, _acc ->
        case detect_cycle(dep, module_map, new_visited) do
          {:cycle, path} -> {:halt, {:cycle, path}}
          :ok -> {:cont, :ok}
        end
      end)
    end
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
  Returns all available modules from the registry.
  """
  def list_all_app_modules do
    Registry.list_app_module_implementations()
  end

  @doc """
  Returns all modules that an org is subscribed to.
  """
  def list_org_app_modules(org_id) do
    subscription_codes =
      org_id
      |> list_org_app_module_subscriptions()
      |> Enum.filter(& &1.active)
      |> Enum.map(& &1.module_code)

    Enum.filter(list_all_app_modules(), fn module -> module.code() in subscription_codes end)
  end

  @doc """
  Lists all module subscriptions for an org.
  """
  def list_org_app_module_subscriptions(org_id) do
    Subscription
    |> where([s], s.org_id == ^org_id)
    |> order_by([s], s.module_code)
    |> Repo.all()
  end

  @doc """
  Gets a specific module subscription for an org.
  """
  def get_org_app_module_subscription(org_id, module_code) do
    Subscription
    |> where([s], s.org_id == ^org_id and s.module_code == ^module_code)
    |> Repo.one()
  end

  @doc """
  Subscribes an org to a module.
  """
  def subscribe_org_to_module(org_id, module_code, opts \\ []) do
    attrs = %{
      org_id: org_id,
      module_code: module_code,
      active: Keyword.get(opts, :active, true),
      expires_at: Keyword.get(opts, :expires_at)
    }

    case get_org_app_module_subscription(org_id, module_code) do
      nil ->
        %Subscription{}
        |> Subscription.changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, subscription} ->
            setup_module_for_org(org_id, module_code)
            {:ok, subscription}

          error ->
            error
        end

      existing_subscription ->
        existing_subscription
        |> Subscription.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Unsubscribes an org from a module.
  """
  def unsubscribe_org_from_module(org_id, module_code) do
    case get_org_app_module_subscription(org_id, module_code) do
      nil ->
        {:error, :not_subscribed}

      subscription ->
        with {:ok, _} <- Repo.delete(subscription),
             :ok <- cleanup_module_for_org(org_id, module_code) do
          {:ok, subscription}
        end
    end
  end

  @doc """
  Activates a module subscription for an org.
  """
  def activate_app_module_subscription(org_id, module_code) do
    case get_org_app_module_subscription(org_id, module_code) do
      nil ->
        subscribe_org_to_module(org_id, module_code, active: true)

      subscription ->
        subscription
        |> Subscription.changeset(%{active: true})
        |> Repo.update()
        |> case do
          {:ok, updated_subscription} ->
            setup_module_for_org(org_id, module_code)
            {:ok, updated_subscription}

          error ->
            error
        end
    end
  end

  @doc """
  Deactivates a module subscription for an org.
  """
  def deactivate_app_module_subscription(org_id, module_code) do
    case get_org_app_module_subscription(org_id, module_code) do
      nil ->
        {:error, :not_subscribed}

      subscription ->
        subscription
        |> Subscription.changeset(%{active: false})
        |> Repo.update()
        |> case do
          {:ok, updated_subscription} ->
            cleanup_module_for_org(org_id, module_code)
            {:ok, updated_subscription}

          error ->
            error
        end
    end
  end

  @doc """
  Checks if an org has access to a specific module.
  """
  def org_has_app_module_access?(org_id, module_code) do
    case get_org_app_module_subscription(org_id, module_code) do
      %{active: true, expires_at: nil} ->
        true

      %{active: true, expires_at: expires_at} ->
        DateTime.before?(DateTime.utc_now(), expires_at)

      _ ->
        false
    end
  end

  @doc """
  Returns changeset for tracking subscription changes.
  """
  def change_module_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.changeset(subscription, attrs)
  end

  @doc """
  Sets up a module for an org by calling the module's setup_org callback.
  """
  def setup_module_for_org(org_id, module_code) do
    case get_app_module_by_code(module_code) do
      nil ->
        {:error, :module_not_found}

      module ->
        try do
          module.setup_org(org_id)
        rescue
          e -> {:error, e}
        end
    end
  end

  @doc """
  Cleans up a module for an org by calling the module's cleanup_org callback.
  """
  def cleanup_module_for_org(org_id, module_code) do
    case get_app_module_by_code(module_code) do
      nil ->
        # Module doesn't exist, nothing to clean up
        :ok

      module ->
        try do
          module.cleanup_org(org_id)
        rescue
          # Don't fail cleanup operations
          _e -> :ok
        end
    end
  end

  @doc """
  Gets route information for all modules available to an org.
  """
  def get_org_app_module_routes(org_id) do
    org_id
    |> list_org_app_modules()
    |> Enum.map(fn module ->
      routes =
        if function_exported?(module, :routes, 0) do
          module.routes()
        else
          %{}
        end

      %{
        code: module.code(),
        name: module.name(),
        routes: routes
      }
    end)
  end

  @doc """
  Gets dashboard widgets for all modules available to an org.
  """
  def get_org_app_module_widgets(org_id) do
    org_id
    |> list_org_app_modules()
    |> Enum.flat_map(fn module ->
      if function_exported?(module, :dashboard_widgets, 0) do
        widgets = module.dashboard_widgets()
        Enum.map(widgets, &Map.put(&1, :module_code, module.code()))
      else
        []
      end
    end)
  end

  @doc """
  Initializes default modules for a new org.
  This can be called when an org is created to set up basic modules.
  """
  def initialize_org_app_modules(org_id, default_modules \\ []) do
    Enum.each(default_modules, fn module_code -> subscribe_org_to_module(org_id, module_code, active: true) end)
  end

  @doc """
  Bulk updates module subscriptions for an org.
  Useful for subscription plan changes.
  """
  def bulk_update_org_app_modules(org_id, module_updates) do
    Enum.each(module_updates, fn {module_code, active} ->
      if active do
        activate_app_module_subscription(org_id, module_code)
      else
        deactivate_app_module_subscription(org_id, module_code)
      end
    end)
  end
end
