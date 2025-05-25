defmodule PetalPro.AppModules.Behaviours.AppModule do
  @moduledoc """
  Behavior that all application modules must implement.
  This defines the contract for module registration and functionality.
  """

  @doc "Returns the unique module code/identifier"
  @callback code() :: String.t()

  @doc "Returns the human-readable module name"
  @callback name() :: String.t()

  @doc "Returns the module description"
  @callback description() :: String.t()

  @doc "Returns the module version"
  @callback version() :: String.t()

  @doc "Setup module for a specific org"
  @callback setup_org(org_id :: integer) :: :ok | {:error, term()}

  @doc "Cleanup module data when removing from a org"
  @callback cleanup_org(org_id :: integer) :: :ok | {:error, term()}

  @doc "Returns route configuration for the module"
  @callback routes() :: map()

  @doc "Returns dashboard widgets for the module (optional)"
  @callback dashboard_widgets() :: [map()]
  @optional_callbacks dashboard_widgets: 0

  @doc "Returns sidebar menu items for the module (optional)"
  @callback sidebar_menu() :: [map()]
  @optional_callbacks sidebar_menu: 0
end
