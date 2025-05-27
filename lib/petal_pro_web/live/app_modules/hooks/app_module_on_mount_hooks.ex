defmodule PetalProWeb.AppModuleOnMountHooks do
  @moduledoc """
  LiveView on_mount hooks for module-based authorization.

  Provides declarative hooks to ensure users have access to specific application modules
  based on their organization's module subscriptions.

  ## Usage

      # Simple module access check
      live_session :crm_session,
        on_mount: [
          {PetalProWeb.AppModuleOnMountHooks, {:require_module, "crm"}}
        ] do
        live "/crm", CRMLive
      end

      # Multiple modules check
      live_session :multi_module_session,
        on_mount: [
          {PetalProWeb.AppModuleOnMountHooks, {:require_any_module, ["crm", "sales"]}}
        ] do
        live "/dashboard", DashboardLive
      end

      # Optional module check (assigns access info without blocking)
      live_session :optional_module_session,
        on_mount: [
          {PetalProWeb.AppModuleOnMountHooks, {:check_module, "crm"}}
        ] do
        live "/features", FeaturesLive
      end
  """

  use PetalProWeb, :verified_routes

  import Phoenix.Component
  import Phoenix.LiveView

  alias PetalPro.AppModules
  alias PetalPro.Orgs.Org

  require Logger

  # Public API - Declarative mount hooks

  @doc """
  Requires access to a specific module. Redirects if access is denied.
  """
  def on_mount({:require_module, module_code}, _params, _session, socket) do
    case check_module_access(socket, module_code) do
      {:ok, module_data} ->
        {:cont, assign_module_data(socket, module_data)}

      {:error, reason} ->
        {:halt, handle_access_denied(socket, module_code, reason)}
    end
  end

  def on_mount({:require_any_module, module_codes}, _params, _session, socket) when is_list(module_codes) do
    case check_any_module_access(socket, module_codes) do
      {:ok, module_data} ->
        {:cont, assign_module_data(socket, module_data)}

      {:error, reason} ->
        {:halt, handle_access_denied(socket, module_codes, reason)}
    end
  end

  def on_mount({:check_module, module_code}, _params, _session, socket) do
    case check_module_access(socket, module_code) do
      {:ok, module_data} ->
        socket =
          socket
          |> assign_module_data(module_data)
          |> assign(:has_module_access, true)

        {:cont, socket}

      {:error, _reason} ->
        socket =
          socket
          |> assign(:current_module, nil)
          |> assign(:has_module_access, false)

        {:cont, socket}
    end
  end

  # Private functions

  defp check_module_access(socket, module_code) do
    with {:ok, org} <- get_current_org(socket),
         {:ok, module_info} <- get_module_info(module_code),
         {:ok, subscription} <- check_module_subscription(org, module_code) do
      {:ok, %{module: module_info, subscription: subscription, org: org}}
    end
  end

  defp check_any_module_access(socket, module_codes) do
    org = get_current_org(socket)

    case org do
      {:ok, org} ->
        find_accessible_module(org, module_codes)

      error ->
        error
    end
  end

  defp find_accessible_module(org, module_codes) do
    Enum.reduce_while(module_codes, {:error, :no_access}, fn module_code, _acc ->
      case check_module_access_for_org(org, module_code) do
        {:ok, module_data} ->
          {:halt, {:ok, module_data}}

        {:error, _} ->
          {:cont, {:error, :no_access}}
      end
    end)
  end

  defp check_module_access_for_org(org, module_code) do
    with {:ok, module_info} <- get_module_info(module_code),
         {:ok, subscription} <- check_module_subscription(org, module_code) do
      {:ok, %{module: module_info, subscription: subscription, org: org}}
    end
  end

  defp get_current_org(%{assigns: %{current_org: %Org{} = org}}), do: {:ok, org}
  defp get_current_org(_socket), do: {:error, :no_current_org}

  defp get_module_info(module_code) do
    case AppModules.get_app_module_by_code(module_code) do
      nil -> {:error, :module_not_found}
      module_info -> {:ok, module_info}
    end
  end

  defp check_module_subscription(org, module_code) do
    case AppModules.get_org_app_module_subscription(org.id, module_code) do
      nil ->
        {:error, :no_subscription}

      %{active: false} ->
        {:error, :subscription_inactive}

      %{active: true} = subscription ->
        if subscription_valid?(subscription) do
          {:ok, subscription}
        else
          {:error, :subscription_expired}
        end
    end
  end

  defp subscription_valid?(%{expires_at: nil}), do: true

  defp subscription_valid?(%{expires_at: expires_at}) do
    DateTime.before?(DateTime.utc_now(), expires_at)
  end

  defp assign_module_data(socket, %{module: module, subscription: subscription}) do
    socket
    |> assign(:current_module, module)
    |> assign(:current_module_subscription, subscription)
  end

  defp handle_access_denied(socket, module_code, reason) when is_binary(module_code) do
    handle_access_denied(socket, [module_code], reason)
  end

  defp handle_access_denied(socket, module_codes, reason) when is_list(module_codes) do
    case reason do
      :no_subscription ->
        redirect_to_upgrade(socket, module_codes)

      :subscription_inactive ->
        redirect_with_error(socket, "Module subscription is inactive")

      :subscription_expired ->
        redirect_with_error(socket, "Module subscription has expired")

      :no_current_org ->
        redirect_with_error(socket, "Organization context required")

      :module_not_found ->
        Logger.warning("Module(s) not found: #{inspect(module_codes)}")
        redirect_with_error(socket, "Feature not available")

      _ ->
        Logger.error("Module access denied: #{inspect(reason)}")
        redirect_with_error(socket, "Access denied")
    end
  end

  defp redirect_with_error(socket, message) do
    socket
    |> put_flash(:error, message)
    |> redirect(to: get_dashboard_path(socket))
  end

  defp redirect_to_upgrade(socket, module_codes) do
    module_names = Enum.map_join(module_codes, ", ", &humanize_module_code/1)
    message = "This feature requires the #{module_names} module. Please upgrade your subscription."

    Logger.warning("Module access denied: #{inspect(module_codes)}")

    socket
    |> put_flash(:info, message)
    |> redirect(to: get_upgrade_path(socket))
  end

  defp get_dashboard_path(%{assigns: %{current_org: %{slug: slug}}}), do: ~p"/app/org/#{slug}"
  defp get_dashboard_path(_socket), do: ~p"/app"

  defp get_upgrade_path(%{assigns: %{current_org: %{slug: slug}}}), do: ~p"/app/org/#{slug}/subscribe"
  defp get_upgrade_path(_socket), do: ~p"/app/subscribe"

  defp humanize_module_code(module_code) do
    module_code
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
