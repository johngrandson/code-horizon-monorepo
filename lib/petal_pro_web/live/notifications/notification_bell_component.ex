defmodule PetalProWeb.NotificationBellComponent do
  @moduledoc """
  A live component to load and render the notification bell and pop-out drawer in the toolbar.

  It receives broadcasts from the user notifications channel directly via a Channel we join in the JS hook.
  This way we can keep real-time updates w/o requiring handle_info/2 everywhere in the app.

  Notifications are read either on_mount/4 of the relevant page by checking request path == read_path, or via the Mark all as read button.

  NOTE: The value returned by the `lc_id/0` function _must_ be given as the id attribute to be accurately targeted by `send_update/3`.
  """
  use PetalProWeb, :live_component
  use PetalComponents

  import PetalProWeb.Notifications.Components

  alias PetalPro.Accounts.User
  alias PetalPro.Notifications

  @doc """
  The live component ID to be given as the id attribute. This is used to target the component for `send_update/3`.
  """
  def lc_id(id_prefix \\ "main"), do: "#{id_prefix}-user-notification-bell"

  @doc """
  The dropdown menu ID to be given as the id attribute. This is used to target it for visibility toggling.
  """
  def dropdown_id(id_prefix \\ "main"), do: "#{id_prefix}-user-notification-drawer"

  @doc """
  The icon button ID to be given as the id attribute. This is used to target it for click event.
  """
  def icon_button_id(id_prefix \\ "main"), do: "#{id_prefix}-user-notification-drawer-btn"

  attr :current_user, :map, required: true

  attr :dropdown_id, :string, default: "user-notification-drawer", doc: "The ID of the dropdown menu."

  attr :dropdown_class, :string,
    default:
      "hidden absolute sm:right-0 -right-14 z-10 p-4 mt-2 origin-top-right border dark:border-gray-700 bg-white dark:dark:bg-gray-800 dark:text-gray-100 rounded-md shadow-lg",
    doc: "The class applied to the dropdown menu container."

  attr :dropdown_width_class, :string,
    default: "w-72 sm:w-96",
    doc: "The width class applied to the dropdown menu container - this is appended to `:dropdown_class`."

  attr :icon_button_id, :string, default: "petal-notification-drawer-btn"
  attr :icon_button_class, :string, default: "rounded-lg"
  attr :query_limit, :integer, default: 20, doc: "The number of notifications to query for."

  attr :limit_increment, :integer,
    default: 5,
    doc: "The amount the query limit is increased each time the user clicks 'Load more'."

  def render(assigns) do
    ~H"""
    <div id={@id} phx-hook="NotificationBellHook" class="relative">
      <.icon_button
        id={@icon_button_id}
        aria-label={gettext("Notification Drawer")}
        size="sm"
        class={@icon_button_class}
        phx-click={toggle_dropdown(@dropdown_id)}
      >
        <%!-- Unread alert dot --%>
        <span
          :if={@unread_count > 0}
          class="absolute w-2 h-2 bg-red-500 rounded-full top-2 right-2.5"
        />
        <.icon name="hero-bell-solid" class="text-gray-500 dark:text-gray-400" />
      </.icon_button>

      <%!-- Popout menu --%>
      <div
        id={@dropdown_id}
        class={"#{@dropdown_class} #{@dropdown_width_class}"}
        phx-click-away={hide_dropdown(@dropdown_id)}
        role="menu"
        aria-orientation="vertical"
        aria-labelledby={@icon_button_id}
        tabindex="-1"
      >
        <div class="flex flex-col space-y-2">
          <div class="flex">
            <span class="my-2 prose">
              <h4 class="text-gray-700 dark:text-gray-100">{gettext("Notifications")}</h4>
            </span>
            <span class="grow" />
            <.button
              color="light"
              size="xs"
              class="my-auto whitespace-nowrap h-7"
              label={gettext("Mark all as read")}
              phx-click="mark_all_as_read"
              phx-target={@myself}
              phx-throttle="1000"
            />
          </div>

          <div class="flex w-full space-x-1 text-sm">
            <.button
              color="light"
              size="md"
              class={tab_btn_class(@current_tab, :unread)}
              label={gettext("Unread")}
              phx-click="show_unread"
              phx-target={@myself}
            />
            <.button
              color="light"
              size="md"
              class={tab_btn_class(@current_tab, :all)}
              label={gettext("All")}
              phx-click="show_all"
              phx-target={@myself}
            />
          </div>
        </div>
        <.empty_state :if={relevant_count(assigns) == 0} current_tab={@current_tab} />
        <.notifications_list
          :if={relevant_count(assigns) > 0}
          myself={@myself}
          current_tab={@current_tab}
          notifications={@notifications}
          query_limit={@query_limit}
          relevant_count={relevant_count(assigns)}
        />
      </div>
    </div>
    """
  end

  defp empty_state(%{current_tab: :unread} = assigns) do
    ~H"""
    <div class="flex justify-center pt-10 pb-8 text-center">
      <div class="flex flex-col space-y-2">
        <p class="text-sm font-semibold text-gray-700 dark:text-gray-100">
          {gettext("You're all up to date")}
        </p>
        <p class="text-sm text-gray-500 dark:text-gray-300">
          {gettext("There are no new notifications at the moment.")}
        </p>
      </div>
    </div>
    """
  end

  defp empty_state(%{current_tab: :all} = assigns) do
    ~H"""
    <div class="flex justify-center pt-10 pb-8 text-center">
      <div class="flex flex-col space-y-2">
        <p class="text-sm font-semibold text-gray-700 dark:text-gray-100">
          {gettext("Nothing to see here")}
        </p>
        <p class="text-sm text-gray-500 dark:text-gray-300">
          {gettext("You haven't received any notifications yet.")}
        </p>
      </div>
    </div>
    """
  end

  defp notifications_list(assigns) do
    ~H"""
    <div class="flex flex-col space-y-1 pt-4 overflow-y-auto max-h-[500px]">
      <.notification_item
        :for={{notification, idx} <- Enum.with_index(@notifications)}
        idx={idx}
        notification={notification}
      />
    </div>
    <div class="flex pt-4 my-auto mt-1 border-t border-gray-200 select-none dark:border-gray-700">
      <p :if={@query_limit < @relevant_count} class="text-sm text-gray-500 dark:text-gray-100">
        {gettext("Showing %{limit} of %{total}",
          limit: @query_limit,
          total: @relevant_count
        )}
      </p>
      <p
        :if={@query_limit >= @relevant_count}
        class="mx-auto text-sm text-gray-500 dark:text-gray-100"
      >
        {gettext("Showing all")}
      </p>
      <span :if={@query_limit < @relevant_count} class="grow" />
      <button
        :if={@query_limit < @relevant_count}
        phx-click="load_more"
        phx-target={@myself}
        class="text-sm font-medium text-primary"
      >
        {gettext("Load more")}
      </button>
    </div>
    """
  end

  defp relevant_count(%{current_tab: :all, total_count: total_count}), do: total_count
  defp relevant_count(%{current_tab: :unread, unread_count: unread_count}), do: unread_count

  defp tab_btn_class(current_tab, current_tab),
    do:
      "#{tab_btn_base_class()} border-primary-500 text-primary-500 focus:text-primary-500 focus:border-primary-500 ring-1 ring-inset ring-primary-500"

  defp tab_btn_class(_current_tab, _tab), do: "#{tab_btn_base_class()}"

  defp tab_btn_base_class, do: "transition-colors w-1/2 hover:border-primary-500 hover:text-primary-500"

  def mount(socket) do
    {:ok,
     assign(socket,
       current_tab: :unread,
       notifications: [],
       total_count: 0,
       unread_count: 0,
       query_limit: 20,
       limit_increment: 5
     )}
  end

  def update(
        %{current_user: %User{} = current_user} = assigns,
        %{assigns: %{current_tab: current_tab, query_limit: default_limit}} = socket
      ) do
    limit = Map.get(assigns, :query_limit, default_limit)

    %{notifications: notifications, total_count: total_count, unread_count: unread_count} =
      load_notifications(current_user, current_tab, limit)

    {:ok,
     socket
     |> push_event("app:join_notifications_channel", %{id: current_user.id})
     |> assign(assigns)
     |> assign(
       notifications: notifications,
       total_count: total_count,
       unread_count: unread_count
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event(
        "hook:refresh_notifications",
        _,
        %{assigns: %{current_tab: current_tab, current_user: current_user, query_limit: limit}} = socket
      ) do
    %{notifications: notifications, total_count: total_count, unread_count: unread_count} =
      load_notifications(current_user, current_tab, limit)

    {:noreply, assign(socket, notifications: notifications, total_count: total_count, unread_count: unread_count)}
  end

  def handle_event("show_all", _, %{assigns: %{current_user: current_user}} = socket) do
    notifications = Notifications.list_user_notifications(current_user, limit: socket.assigns.query_limit)
    {:noreply, assign(socket, current_tab: :all, notifications: notifications)}
  end

  def handle_event("show_unread", _, %{assigns: %{current_user: current_user}} = socket) do
    notifications =
      Notifications.list_user_notifications(current_user, unread_only: true, limit: socket.assigns.query_limit)

    {:noreply, assign(socket, current_tab: :unread, notifications: notifications, unread_count: length(notifications))}
  end

  def handle_event("mark_all_as_read", _, %{assigns: %{current_tab: current_tab}} = socket) do
    Notifications.mark_all_user_notifications_as_read(socket.assigns.current_user)

    case current_tab do
      :unread ->
        {:noreply, assign(socket, notifications: [], unread_count: 0)}

      :all ->
        {:noreply, assign(socket, unread_count: 0)}
    end
  end

  def handle_event(
        "load_more",
        _,
        %{
          assigns: %{
            current_user: %User{} = current_user,
            current_tab: :all,
            query_limit: limit,
            limit_increment: limit_increment,
            total_count: total_count
          }
        } = socket
      ) do
    if limit < total_count do
      new_limit = limit + limit_increment

      %{notifications: notifications, total_count: total_count, unread_count: unread_count} =
        load_notifications(current_user, :all, new_limit)

      {:noreply,
       assign(socket,
         notifications: notifications,
         total_count: total_count,
         unread_count: unread_count,
         query_limit: new_limit
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "load_more",
        _,
        %{
          assigns: %{
            current_user: %User{} = current_user,
            current_tab: :unread,
            query_limit: limit,
            limit_increment: limit_increment,
            unread_count: unread_count
          }
        } = socket
      ) do
    if limit < unread_count do
      new_limit = limit + limit_increment

      %{notifications: notifications, total_count: total_count, unread_count: unread_count} =
        load_notifications(current_user, :unread, new_limit)

      {:noreply,
       assign(socket,
         notifications: notifications,
         total_count: total_count,
         unread_count: unread_count,
         query_limit: new_limit
       )}
    else
      {:noreply, socket}
    end
  end

  defp load_notifications(current_user, current_tab, limit) do
    notifications = Notifications.list_user_notifications(current_user, unread_only: current_tab == :unread, limit: limit)
    total_count = Notifications.count_user_notifications(current_user)
    unread_count = Notifications.count_unread_user_notifications(current_user)

    %{notifications: notifications, total_count: total_count, unread_count: unread_count}
  end

  defp toggle_dropdown(js \\ %JS{}, elem_id) do
    JS.toggle(js,
      to: "##{elem_id}",
      in: {"transition ease-out duration-100", "transform opacity-0 scale-95", "transform opacity-100 scale-100"},
      out: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"}
    )
  end

  defp hide_dropdown(js \\ %JS{}, elem_id) do
    JS.hide(js,
      to: "##{elem_id}",
      transition: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"}
    )
  end
end
