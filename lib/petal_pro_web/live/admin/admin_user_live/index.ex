defmodule PetalProWeb.AdminUserLive.Index do
  @moduledoc """
  A live view to admin users on the platform (edit/suspend/delete).
  """
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent

  alias PetalPro.Accounts
  alias PetalPro.Accounts.User
  alias PetalPro.Accounts.UserQuery
  alias PetalPro.Billing.Customers
  alias PetalProWeb.DataTable
  alias PetalProWeb.UserAuth

  @billing_provider Application.compile_env(:petal_pro, :billing_provider)

  @data_table_opts [
    default_limit: 50,
    default_order: %{
      order_by: [:id, :inserted_at],
      order_directions: [:asc, :asc]
    },
    filterable: [:id, :name, :email, :is_suspended, :is_deleted, :inserted_at],
    sortable: [:id, :name, :email, :is_suspended, :is_deleted, :inserted_at]
  ]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(PetalPro.PubSub, "users")

    {:ok,
     assign(socket,
       index_params: nil,
       page_title: gettext("Users"),
       billing_provider: @billing_provider,
       form: nil,
       base_filters_form:
         build_base_filters_form(%{
           show_is_suspended: false,
           show_is_deleted: false,
           online: false
         })
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :index, params) do
    socket
    |> assign_users(params)
    |> assign(
      index_params: params,
      changeset: nil,
      form: nil,
      online_users: "users" |> PetalProWeb.Presence.list() |> Map.keys() |> Enum.map(&String.to_integer/1),
      page_title: gettext("Users")
    )
  end

  def apply_action(socket, :edit, %{"user_id" => id} = params) do
    user = id |> Accounts.get_user!() |> Accounts.preload_memberships()

    socket
    |> assign_users(params)
    |> assign(
      index_params: Map.drop(params, ["user_id"]),
      changeset: nil,
      page_title: gettext("Edit %{model}", model: gettext("User")),
      user: user,
      form: to_form(Accounts.change_user_as_admin(user))
    )
  end

  def apply_action(socket, :new, params) do
    socket
    |> assign_users(params)
    |> assign(
      index_params: params,
      changeset: nil,
      page_title: gettext("New %{model}", model: gettext("User")),
      user: %User{},
      form: to_form(Accounts.change_user_as_admin(%User{}))
    )
  end

  defp current_index_path(index_params) do
    ~p"/admin/users?#{index_params || %{}}"
  end

  @impl true
  def handle_event("toggle_base_filters", %{"base_filters" => base_filters}, socket) do
    socket =
      socket
      |> assign(base_filters_form: build_base_filters_form(base_filters))
      |> assign_users(socket.assigns[:index_params] || %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: ~p"/admin/users?#{query_params}")}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, patch_back_to_index(socket)}
  end

  @impl true
  def handle_event("sync_user_billing", %{"id" => user_id}, socket) do
    with %Customers.Customer{} = customer <- Customers.get_customer_by_source(:user, user_id),
         :ok <- @billing_provider.sync_subscription(customer) do
      socket =
        socket
        |> put_flash(:info, gettext("%{model} billing synced", model: gettext("User")))
        |> patch_back_to_index()

      {:noreply, socket}
    else
      _ ->
        {:noreply, put_flash(socket, :info, gettext("No %{model} billing found", model: gettext("User")))}
    end
  end

  @impl true
  def handle_event("suspend_user", params, socket) do
    user = Accounts.get_user!(params["id"])

    case Accounts.suspend_user(user) do
      {:ok, user} ->
        UserAuth.log_out_another_user(user)

        socket =
          socket
          |> put_flash(:info, gettext("User suspended"))
          |> patch_back_to_index()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("undo_suspend_user", params, socket) do
    user = Accounts.get_user!(params["id"])

    case Accounts.undo_suspend_user(user) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, gettext("User no longer suspended"))
          |> patch_back_to_index()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("delete_user", params, socket) do
    user = Accounts.get_user!(params["id"])

    case Accounts.delete_user(user) do
      {:ok, user} ->
        UserAuth.log_out_another_user(user)

        socket =
          socket
          |> put_flash(:info, gettext("User deleted"))
          |> patch_back_to_index()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("undo_delete_user", params, socket) do
    user = Accounts.get_user!(params["id"])

    case Accounts.undo_delete_user(user) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, gettext("User no longer deleted"))
          |> patch_back_to_index()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user_id, _}, socket ->
      users =
        Enum.map(socket.assigns.users, fn user ->
          if Integer.to_string(user.id) == user_id, do: PetalProWeb.Presence.online_user?(user), else: user
        end)

      assign(socket, users: users)
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user_id, _}, socket ->
      users =
        Enum.map(socket.assigns.users, fn user ->
          if Integer.to_string(user.id) == user_id, do: PetalProWeb.Presence.online_user?(user), else: user
        end)

      assign(socket, users: users)
    end)
  end

  def build_base_filters_form(params \\ %{}) do
    types = %{
      show_is_suspended: :boolean,
      show_is_deleted: :boolean,
      online: :boolean
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> to_form(as: :base_filters)
  end

  defp patch_back_to_index(socket) do
    push_patch(socket, to: ~p"/admin/users?#{socket.assigns[:index_params] || []}")
  end

  defp assign_users(socket, params) do
    query = User

    query =
      if Phoenix.HTML.Form.input_value(socket.assigns.base_filters_form, :online) do
        UserQuery.online?(query)
      else
        query
      end

    query =
      if Phoenix.HTML.Form.input_value(socket.assigns.base_filters_form, :show_is_deleted) do
        query
      else
        UserQuery.deleted?(query, false)
      end

    query =
      if Phoenix.HTML.Form.input_value(socket.assigns.base_filters_form, :show_is_suspended) do
        query
      else
        UserQuery.suspended?(query, false)
      end

    {users, meta} = DataTable.search(query, params, @data_table_opts)
    users = PetalProWeb.Presence.online_users(users)
    assign(socket, %{users: users, meta: meta})
  end

  def user_actions(assigns) do
    ~H"""
    <div class="flex items-center" id={"user_actions_container_#{@user.id}"}>
      <.dropdown
        class="dark:shadow-lg"
        options_container_id={"user_options_#{@user.id}"}
        menu_items_wrapper_class="dark:border dark:border-gray-600"
      >
        <.dropdown_menu_item link_type="live_patch" to={~p"/admin/users/#{@user}"}>
          <.icon name="hero-information-circle" class="w-5 h-5" />
          {gettext("View")}
        </.dropdown_menu_item>

        <.dropdown_menu_item link_type="live_patch" to={~p"/admin/users/#{@user}/edit"}>
          <.icon name="hero-pencil" class="w-5 h-5" />
          {gettext("Edit")}
        </.dropdown_menu_item>

        <.dropdown_menu_item
          :if={@billing_provider}
          phx-click={JS.push("sync_user_billing")}
          phx-value-id={@user.id}
          data-confirm={gettext("Are you sure?")}
        >
          <.icon name="hero-arrow-path" class="w-5 h-5" />
          {gettext("Sync Billing")}
        </.dropdown_menu_item>

        <.dropdown_menu_item link_type="live_redirect" to={~p"/admin/logs?#{[user_id: @user.id]}"}>
          <.icon name="hero-document-text" class="w-5 h-5" />
          {gettext("View logs")}
        </.dropdown_menu_item>

        <%= if @user.is_suspended do %>
          <.dropdown_menu_item
            phx-click={
              JS.push("undo_suspend_user")
              |> JS.hide(to: "#user_options_#{@user.id}")
            }
            phx-value-id={@user.id}
            data-confirm={gettext("Are you sure?")}
          >
            <.icon name="hero-arrow-uturn-down" class="w-5 h-5" />
            {gettext("Undo suspend")}
          </.dropdown_menu_item>
        <% else %>
          <.dropdown_menu_item
            phx-click={
              JS.push("suspend_user")
              |> JS.hide(to: "#user_options_#{@user.id}")
            }
            phx-value-id={@user.id}
            data-confirm={
                          "Are you sure? #{user_name(@user)} will be logged out and unable to sign in."
                      }
          >
            <.icon name="hero-no-symbol" class="w-5 h-5" />
            {gettext("Suspend")}
          </.dropdown_menu_item>
        <% end %>

        <%= if PetalPro.Accounts.Permissions.can_impersonate?(@user, @current_user) do %>
          <.dropdown_menu_item link_type="a" to={~p"/auth/impersonate?id=#{@user.id}"} method="post">
            <.icon name="hero-user" class="w-5 h-5" /> {gettext("Impersonate")}
          </.dropdown_menu_item>
        <% end %>

        <%= if @user.is_deleted do %>
          <.dropdown_menu_item
            phx-click={
              JS.push("undo_delete_user")
              |> JS.hide(to: "#user_options_#{@user.id}")
            }
            phx-value-id={@user.id}
            data-confirm={gettext("Are you sure?")}
          >
            <.icon name="hero-check" class="w-5 h-5" /> {gettext("Undo delete")}
          </.dropdown_menu_item>
        <% else %>
          <.dropdown_menu_item
            phx-click={
              JS.hide(to: "#user_options_#{@user.id}")
              |> JS.push("delete_user")
            }
            phx-value-id={@user.id}
            data-confirm={gettext("Are you sure?")}
          >
            <.icon name="hero-trash" class="w-5 h-5" /> {gettext("Delete")}
          </.dropdown_menu_item>
        <% end %>
      </.dropdown>
    </div>
    """
  end
end
