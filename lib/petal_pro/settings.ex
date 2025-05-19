defmodule PetalPro.Settings do
  @moduledoc """
  The Settings context handles all global application settings.
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias PetalPro.Accounts
  alias PetalPro.Orgs
  alias PetalPro.Repo
  alias PetalPro.Settings.Setting

  require Logger

  @type setting_key :: String.t() | atom()
  @type setting_value :: any()
  @type setting_attrs :: %{required(atom()) => any()}

  @doc """
  Gets a setting by key. Returns nil if not found.
  """
  @spec get_setting(setting_key()) :: Setting.t() | nil
  def get_setting(key) when is_atom(key), do: get_setting(Atom.to_string(key))

  def get_setting(key) when is_binary(key) do
    Repo.get_by(Setting, key: key)
  end

  @doc """
  Gets a setting value by key. Returns the default if not found.
  """
  @spec get_setting_value(setting_key(), setting_value()) :: setting_value()
  def get_setting_value(key, default \\ nil) do
    case get_setting(key) do
      nil -> default
      %Setting{value: %{"value" => value}} -> value
      %Setting{value: value} -> value
    end
  end

  @doc """
  Creates or updates a setting.
  """
  @spec upsert_setting(setting_key(), setting_value(), keyword()) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  def upsert_setting(key, value, opts \\ []) do
    attrs = %{
      key: key,
      value: value,
      description: Keyword.get(opts, :description),
      is_public: Keyword.get(opts, :is_public, false)
    }

    case_result =
      case get_setting(key) do
        nil -> %Setting{}
        setting -> setting
      end

    case_result
    |> Setting.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Gets all public settings.
  """
  @spec list_public_settings() :: [Setting.t()]
  def list_public_settings do
    Setting
    |> where([s], s.is_public == true)
    |> Repo.all()
  end

  @doc """
  Initializes default settings if they don't exist.
  This should be called during application startup.
  """
  @spec init_default_settings() :: :ok | :error
  def init_default_settings do
    default_settings = [
      %{
        key: "maintenance_mode",
        value: %{"value" => false},
        description: "When enabled, shows maintenance page to non-admin users",
        is_public: true
      },
      %{
        key: "max_orgs_free_user",
        value: %{"value" => 1},
        description: "Maximum number of organizations a free user can create",
        is_public: true
      },
      %{
        key: "allow_signups",
        value: %{"value" => true},
        description: "Whether new user signups are allowed",
        is_public: true
      },
      %{
        key: "enable_public_api",
        value: %{"value" => false},
        description: "Whether the public API is enabled",
        is_public: true
      }
    ]

    Multi.new()
    |> Multi.run(:insert_defaults, fn _repo, _changes ->
      Enum.reduce_while(default_settings, {:ok, []}, fn setting, acc ->
        case upsert_setting(setting.key, setting.value,
               description: setting.description,
               is_public: setting.is_public
             ) do
          {:ok, setting} ->
            {:cont, {:ok, [setting | acc]}}

          {:error, changeset} ->
            Logger.error("Failed to upsert setting #{setting.key}: #{inspect(changeset.errors)}")
            {:halt, {:error, changeset}}
        end
      end)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        :ok

      {:error, _, changeset, _} ->
        Logger.error("Failed to initialize settings: #{inspect(changeset.errors)}")
        :error
    end
  end

  # Global settings helpers with type specs

  @doc """
  Checks if maintenance mode is active.
  """
  @spec maintenance_mode?() :: boolean()
  def maintenance_mode?, do: get_setting_value("maintenance_mode", false)

  @doc """
  Gets the maximum number of organizations a free user can create.
  """
  @spec max_orgs_for_free_user() :: integer()
  def max_orgs_for_free_user, do: get_setting_value("max_orgs_free_user", 1)

  @doc """
  Checks if signups are allowed.
  """
  @spec allow_signups?() :: boolean()
  def allow_signups?, do: get_setting_value("allow_signups", true)

  @doc """
  Checks if public API is enabled.
  """
  @spec public_api_enabled?() :: boolean()
  def public_api_enabled?, do: get_setting_value("enable_public_api", false)

  @doc """
  Checks if a user has reached the maximum number of organizations.
  """
  @spec user_reached_org_limit?(Accounts.User.t()) :: boolean()
  def user_reached_org_limit?(user) do
    org_count = length(Orgs.list_orgs(user))
    org_count >= max_orgs_for_free_user()
  end
end
