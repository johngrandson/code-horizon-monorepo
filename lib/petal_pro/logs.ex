defmodule PetalPro.Logs do
  @moduledoc """
  A context file for CRUDing logs
  """

  import Ecto.Query, warn: false

  alias PetalPro.Extensions.Ecto.QueryExt
  alias PetalPro.Logs.Log
  alias PetalPro.Repo

  require Logger

  # Logs allow you to keep track of user activity.
  # This helps with both analytics and customer support (easy to look up a user and see what they've done)
  # If you don't want to store logs on your db, you could rewrite this file to send them to a 3rd
  # party service like https://www.datadoghq.com/

  def get(id), do: Repo.get(Log, id)

  def create(attrs \\ %{}) do
    case %Log{}
         |> Log.changeset(attrs)
         |> Repo.insert() do
      {:ok, log} ->
        PetalProWeb.Endpoint.broadcast("logs", "new-log", log)
        {:ok, log}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def log(action, params) do
    action
    |> build(params)
    |> create()
  end

  def log_async(action, params) do
    PetalPro.BackgroundTask.run(fn ->
      log(action, params)
    end)
  end

  @doc """
  Builds a log from the given action and params.

  Examples:

      PetalPro.Logs.log("orgs.create_invitation", %{
        user: socket.assigns.current_user,
        target_user_id: nil,
        org_id: org.id,
      })

      # When one user performs an action on another user:
      PetalPro.Logs.log("orgs.delete_member", %{
        user: socket.assigns.current_user,
        target_user: member_user,
        org_id: org.id,
      })
  """
  def build(action, params) do
    user_id = if params[:user], do: params.user.id, else: params[:user_id]
    is_admin = if params[:user], do: params.user.role == :admin
    user_role = if params[:user], do: to_string(params.user.role)

    org_id = if params[:org], do: params.org.id, else: params[:org_id]

    billing_customer_id = if params[:customer], do: params.customer.id, else: params[:billing_customer_id]

    target_user_id = if params[:target_user], do: params.target_user.id, else: params[:target_user_id]

    attrs = %{
      user_id: user_id,
      org_id: org_id,
      billing_customer_id: billing_customer_id,
      target_user_id: target_user_id,
      action: action,
      is_admin: is_admin,
      user_role: to_string(user_role),
      metadata: params[:metadata] || %{}
    }

    if user_id do
      attrs
    else
      Map.put(attrs, :user_type, "system")
    end
  end

  @doc """
  Create a log as a multi.

  Examples:

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:post, changeset)
      |> Logs.multi(fn %{post: post} ->
        Logs.build("post.insert", %{user: user, metadata: %{post_id: post.id}})
      end)
  """
  def multi(multi, fun) when is_function(fun) do
    multi
    |> Ecto.Multi.insert(:log, fn previous_multi_results ->
      log_params = fun.(previous_multi_results)
      Log.changeset(%Log{}, log_params)
    end)
    |> Ecto.Multi.run(:broadcast_log, fn _repo, %{log: log} ->
      PetalProWeb.Endpoint.broadcast("logs", "new-log", log)
      {:ok, nil}
    end)
  end

  def exists?(params) do
    Log
    |> QueryBuilder.where(params)
    |> PetalPro.Repo.exists?()
  end

  def get_last_log_of_user(user) do
    user.id
    |> PetalPro.Logs.LogQuery.by_user()
    |> PetalPro.Logs.LogQuery.order_by(:newest)
    |> QueryExt.limit(1)
    |> PetalPro.Repo.one()
  end
end
