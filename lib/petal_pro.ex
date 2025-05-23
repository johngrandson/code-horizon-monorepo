defmodule PetalPro do
  @moduledoc """
  PetalPro keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Looks up `Application` config or raises if keyspace is not configured.
  ## Examples
      config :petal_pro, :files, [
        uploads_dir: Path.expand("../priv/uploads", __DIR__),
        host: [scheme: "http", host: "localhost", port: 4000],
      ]
      iex> PetalPro.config([:files, :uploads_dir])
      iex> PetalPro.config([:files, :host, :port])
  """
  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:petal_pro, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{inspect(keyspace)}"
      end
    end)
  end

  def config(key, default \\ nil) when is_atom(key) do
    Application.get_env(:petal_pro, key, default)
  end

  @doc """
  Returns `true` if the project is in GDPR mode or `false` if not. Defaults to `false` in case no configuration is provided.
  """
  def gdpr_mode, do: config(:gdpr_mode, false)
end
