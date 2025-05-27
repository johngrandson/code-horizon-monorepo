defmodule PetalProWeb.DataTable.Actions do
  @moduledoc """
  Reusable data table actions dropdown component.
  """
  use Phoenix.Component
  use PetalProWeb, :verified_routes
  use PetalComponents
  use Gettext, backend: PetalProWeb.Gettext

  attr :item, :any, required: true
  attr :actions, :list, required: true

  def data_table_actions(assigns) do
    ~H"""
    <div class="relative inline-block text-left" x-data="{ open: false }" @click.away="open = false">
      <button
        type="button"
        @click="open = !open"
        class="inline-flex items-center justify-center w-8 h-8 rounded-lg border border-stone-200 bg-white text-stone-600 shadow-2xs transition-all hover:bg-stone-50 hover:text-stone-800 focus:outline-hidden focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-primary-500 dark:border-neutral-700 dark:bg-neutral-800 dark:text-neutral-400 dark:hover:bg-neutral-700 dark:hover:text-neutral-200"
      >
        <span class="sr-only">Open options</span>
        <.icon name="hero-ellipsis-vertical" class="size-4" />
      </button>

      <div
        x-show="open"
        x-transition:enter="transition ease-out duration-100"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-75"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
        class="absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-stone-200 ring-opacity-9 focus:outline-none dark:bg-neutral-800 dark:ring-white/10"
        role="menu"
      >
        <div class="py-1">
          <%= for action <- @actions do %>
            <.render_action action={action} item={@item} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Divider action
  defp render_action(%{action: %{type: :divider}} = assigns) do
    ~H"""
    <div class="my-1.5 border-t border-slate-200/80 dark:border-slate-700/80"></div>
    """
  end

  # View action
  defp render_action(%{action: %{type: :view}} = assigns) do
    ~H"""
    <.link
      navigate={@action.route}
      class="group flex w-full items-center gap-3 px-3 py-1.5 text-sm font-medium text-slate-700 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-slate-100"
    >
      <.icon
        name={Map.get(@action, :icon, "hero-eye")}
        class="size-5 text-slate-500 dark:text-slate-400"
      />
      <span>{Map.get(@action, :label, gettext("View"))}</span>
    </.link>
    """
  end

  # Edit action
  defp render_action(%{action: %{type: :edit}} = assigns) do
    ~H"""
    <.link
      patch={@action.route}
      class="group flex w-full items-center gap-3 px-3 py-1.5 text-sm font-medium text-slate-700 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-slate-100"
    >
      <.icon
        name={Map.get(@action, :icon, "hero-pencil")}
        class="size-5 text-slate-500 dark:text-slate-400"
      />
      <span>{Map.get(@action, :label, gettext("Edit"))}</span>
    </.link>
    """
  end

  # Delete action
  defp render_action(%{action: %{type: :delete}} = assigns) do
    ~H"""
    <button
      type="button"
      phx-click={Map.get(@action, :event, "delete")}
      phx-value-id={get_item_id(@item)}
      data-confirm={Map.get(@action, :confirm, gettext("Are you sure?"))}
      class={[
        "group flex w-full items-center gap-3 px-3 py-1.5 text-sm font-medium text-red-600 transition-colors duration-200 hover:bg-red-50 hover:text-red-700 dark:text-red-400 dark:hover:bg-red-950/30 dark:hover:text-red-300",
        Map.get(@action, :class, "")
      ]}
    >
      <.icon
        name={Map.get(@action, :icon, "hero-trash")}
        class="size-5 text-red-500 dark:text-red-400"
      />
      <span>{Map.get(@action, :label, gettext("Delete"))}</span>
    </button>
    """
  end

  # Custom action
  defp render_action(%{action: %{type: :custom}} = assigns) do
    ~H"""
    <button
      type="button"
      phx-click={@action.event}
      phx-value-id={get_item_id(@item)}
      {build_phx_values(@action)}
      data-confirm={Map.get(@action, :confirm)}
      class={[
        "group flex w-full items-center gap-3 px-3 py-1.5 text-sm font-medium text-slate-700 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-slate-100",
        Map.get(@action, :class, "")
      ]}
    >
      <.icon
        :if={@action[:icon]}
        name={@action.icon}
        class="size-5 text-slate-500 dark:text-slate-400"
      />
      <span>{@action.label}</span>
    </button>
    """
  end

  defp get_item_id(item) when is_map(item) do
    Map.get(item, :id) || Map.get(item, "id")
  end

  defp build_phx_values(action) do
    case Map.get(action, :phx_value) do
      nil ->
        []

      values when is_map(values) ->
        Enum.map(values, fn {k, v} -> {"phx-value-#{k}", v} end)

      _ ->
        []
    end
  end
end
