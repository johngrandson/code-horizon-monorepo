defmodule PetalProWeb.PageComponents do
  @moduledoc false
  use Phoenix.Component
  use PetalComponents

  @doc """
  Allows you to have a heading on the left side, and some action buttons on the right (default slot)
  """

  # attr :icon, :string, default: nil
  # attr :class, :string, default: ""
  # attr :title, :string, required: true
  # slot(:inner_block)

  # def page_header(assigns) do
  #   assigns = assign_new(assigns, :inner_block, fn -> nil end)

  #   ~H"""
  #   <div class={["mb-8 sm:flex sm:justify-between sm:items-center", @class]}>
  #     <div class="mb-4 sm:mb-0 flex gap-2 items-center">
  #       <.icon :if={@icon} name={@icon} class="w-10 h-10" />
  #       <.h2 class="!mb-0">
  #         {@title}
  #       </.h2>
  #     </div>

  #     <div class="flex gap-2 items-center">
  #       <%= if @inner_block do %>
  #         {render_slot(@inner_block)}
  #       <% end %>
  #     </div>
  #   </div>
  #   """
  # end

  attr :title, :string, required: true, doc: "Header title"
  attr :description, :string, default: nil, doc: "Optional description text"
  attr :class, :string, default: "mb-4", doc: "Additional CSS classes"

  slot :action, doc: "Slot for action buttons" do
    attr :label, :string
    attr :to, :string
    attr :color, :string
    attr :link_type, :string
    attr :icon, :string
  end

  def page_header(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex-row items-center justify-between p-1 space-y-3 sm:flex sm:space-y-0 sm:space-x-4">
        <div>
          <h1 class="text-3xl font-extrabold dark:text-white">{@title}</h1>
          <%= if @description do %>
            <p class="text-gray-500 dark:text-gray-400">
              {@description}
            </p>
          <% end %>
        </div>
        <%= if Enum.any?(@action) do %>
          <div class="flex gap-2">
            <%= for action <- @action do %>
              <.button
                size="sm"
                color={Map.get(action, :color, "primary")}
                link_type={Map.get(action, :link_type, "live_patch")}
                to={action.to}
              >
                <%= if Map.has_key?(action, :icon) do %>
                  <.icon name={action.icon} class="w-4 h-4 mr-2" />
                <% end %>
                {action.label}
              </.button>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc "Gives you a white background with shadow."
  attr :class, :string, default: ""
  attr :padded, :boolean, default: false
  attr :rest, :global
  slot(:inner_block)

  def box(assigns) do
    ~H"""
    <div
      {@rest}
      class={[
        "bg-white dark:bg-gray-800 dark:border dark:border-gray-700 rounded-lg shadow-sm overflow-hidden",
        @class,
        if(@padded, do: "px-4 py-8 sm:px-10", else: "")
      ]}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Provides a container with a sidebar on the left and main content on the right. Useful for things like user settings.

  ---------------------------------
  | Sidebar | Main                |
  |         |                     |
  |         |                     |
  |         |                     |
  ---------------------------------
  """

  attr :current_page, :atom

  attr :menu_items, :list,
    required: true,
    doc: "list of maps with keys :name, :path, :label, :icon (heroicon class)"

  slot(:inner_block)

  def sidebar_tabs_container(assigns) do
    ~H"""
    <.box class="flex flex-col border border-gray-200 divide-y divide-gray-200 dark:border-none dark:divide-gray-700 md:divide-y-0 md:divide-x md:flex-row">
      <div class="shrink-0 w-full py-6 md:w-72">
        <%= for menu_item <- @menu_items do %>
          <.sidebar_menu_item current={@current_page} {menu_item} />
        <% end %>
      </div>

      <div class="grow px-4 py-6 sm:p-6 lg:pb-8">
        {render_slot(@inner_block)}
      </div>
    </.box>
    """
  end

  attr :current, :atom
  attr :name, :string
  attr :path, :string
  attr :label, :string
  attr :icon, :string

  def sidebar_menu_item(assigns) do
    assigns = assign(assigns, :is_active?, assigns.current == assigns.name)

    ~H"""
    <.link
      navigate={@path}
      class={[
        menu_item_classes(@is_active?),
        "flex items-center px-3 py-2 text-sm font-medium border-transparent group"
      ]}
    >
      <.icon name={@icon} class={menu_item_icon_classes(@is_active?) <> " shrink-0 w-6 h-6 mx-3"} />
      <div>
        {@label}
      </div>
    </.link>
    """
  end

  defp menu_item_classes(true),
    do: "bg-gray-100 border-gray-500 text-gray-700 dark:bg-gray-700 dark:text-gray-100 dark:hover:text-white"

  defp menu_item_classes(false),
    do:
      "text-gray-900 hover:bg-gray-50 hover:text-gray-900 dark:text-gray-400 dark:hover:bg-gray-700/70 dark:hover:text-gray-50"

  defp menu_item_icon_classes(true),
    do: "text-gray-500 group-hover:text-gray-500 dark:text-gray-100 dark:group-hover:text-white"

  defp menu_item_icon_classes(false),
    do: "text-gray-500 group-hover:text-gray-500 dark:text-gray-400 dark:group-hover:text-gray-400"
end
