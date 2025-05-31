defmodule PetalProWeb.Components.ActionDropdown do
  @moduledoc """
  Reusable action dropdown component using only Elixir and Phoenix LiveView.
  Fixed version - no JS/event mixing issues.
  """
  use Phoenix.Component
  use PetalComponents

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true, doc: "Unique identifier for the dropdown"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :entity_id, :string, required: true, doc: "ID of the entity (org, user, etc.)"
  attr :entity_type, :atom, default: :org, doc: "Type of entity (:org, :user, etc.)"
  attr :can_edit?, :boolean, default: true, doc: "Whether user can edit this entity"
  attr :can_delete?, :boolean, default: true, doc: "Whether user can delete this entity"
  attr :edit_url, :string, default: "edit_entity", doc: "URL for edit action"
  attr :delete_url, :string, default: "delete_entity", doc: "URL for delete action"
  attr :edit_label, :string, default: nil, doc: "Custom label for edit action"
  attr :delete_label, :string, default: nil, doc: "Custom label for delete action"

  slot :action, doc: "Custom action slots" do
    attr :event, :string, doc: "Phoenix event name"
    attr :icon, :string, doc: "Heroicon name"
    attr :label, :string, doc: "Action label"
    attr :class, :string, doc: "Additional CSS classes for this action"
    attr :confirm, :string, doc: "Confirmation message"
  end

  def action_dropdown(assigns) do
    edit_label =
      case assigns.entity_type do
        :org -> "Edit organization"
        :user -> "Edit user"
        _ -> "Edit"
      end

    delete_label =
      case assigns.entity_type do
        :org -> "Delete organization"
        :user -> "Delete user"
        _ -> "Delete"
      end

    assigns = assign(assigns, edit_label: edit_label, delete_label: delete_label)

    ~H"""
    <div class={["relative inline-flex", @class]}>
      <!-- Dropdown Trigger Button -->
      <button
        type="button"
        class="flex justify-center items-center gap-x-3 size-8 text-sm border border-gray-200 text-gray-600 hover:bg-gray-100 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-none focus:bg-gray-100 dark:border-neutral-700 dark:text-neutral-400 dark:hover:bg-neutral-700 dark:focus:bg-neutral-700 dark:hover:text-neutral-200 dark:focus:text-neutral-200 transition-all duration-200"
        aria-haspopup="menu"
        aria-label="More actions"
        phx-click={
          JS.toggle(
            to: "#dropdown-menu-#{@id}",
            in: {
              "transition ease-out duration-200",
              "opacity-0 scale-95 translate-y-1",
              "opacity-100 scale-100 translate-y-0"
            },
            out: {
              "transition ease-in duration-150",
              "opacity-100 scale-100 translate-y-0",
              "opacity-0 scale-95 translate-y-1"
            }
          )
        }
      >
        <.icon name="hero-ellipsis-horizontal" class="w-4 h-4" />
      </button>
      
    <!-- Dropdown Menu -->
      <div
        id={"dropdown-menu-#{@id}"}
        class="absolute right-0 top-full mt-2 w-48 hidden opacity-0 scale-95 translate-y-1 transition-all duration-200 transform origin-top-right z-50 bg-white rounded-xl shadow-xl border border-gray-200 dark:bg-neutral-900 dark:border-neutral-700"
        role="menu"
        aria-orientation="vertical"
        phx-click-away={JS.hide(to: "#dropdown-menu-#{@id}")}
      >
        <div class="p-1 space-y-0.5">
          <!-- Edit Action -->
          <%= if @can_edit? do %>
            <.link
              navigate={@edit_url}
              type="button"
              phx-click="dropdown_action"
              phx-value-action={:edit}
              phx-value-id={@entity_id}
              class="w-full flex items-center gap-x-2 py-2 px-3 rounded-lg text-sm text-gray-800 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none focus:outline-none focus:bg-gray-100 dark:text-neutral-300 dark:hover:bg-neutral-800 dark:focus:bg-neutral-800 transition-colors"
            >
              <.icon name="hero-pencil-square" class="w-4 h-4" />
              {@edit_label}
            </.link>
          <% end %>

          <%= for action <- @action do %>
            <.link
              navigate={action.event}
              type="button"
              phx-click="dropdown_action"
              phx-value-action={action.event}
              phx-value-id={@entity_id}
              data-confirm={Map.get(action, :confirm)}
              class={[
                "w-full flex items-center gap-x-2 py-2 px-3 rounded-lg text-sm text-gray-800 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none focus:outline-none focus:bg-gray-100 dark:text-neutral-300 dark:hover:bg-neutral-800 dark:focus:bg-neutral-800 transition-colors",
                Map.get(action, :class, "")
              ]}
            >
              <%= if Map.has_key?(action, :icon) do %>
                <.icon name={action.icon} class="w-4 h-4" />
              <% end %>
              {action.label}
            </.link>
          <% end %>

          <%= if (@can_edit? or length(@action) > 0) and @can_delete? do %>
            <hr class="my-1 border-gray-200 dark:border-neutral-700" />
          <% end %>

          <%= if @can_delete? do %>
            <button
              type="button"
              phx-click="dropdown_action"
              phx-value-action="delete"
              phx-value-id={@entity_id}
              data-confirm={"Are you sure you want to delete this #{@entity_type}?"}
              class="w-full flex items-center gap-x-2 py-2 px-3 rounded-lg text-sm text-red-600 hover:bg-red-50 disabled:opacity-50 disabled:pointer-events-none focus:outline-none focus:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/20 dark:focus:bg-red-900/20 transition-colors"
            >
              <.icon name="hero-trash" class="w-4 h-4" />
              {@delete_label}
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
