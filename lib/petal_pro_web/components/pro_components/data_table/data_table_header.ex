defmodule PetalProWeb.DataTable.Header do
  @moduledoc false
  use Phoenix.Component
  use Gettext, backend: PetalProWeb.Gettext

  import PetalComponents.Dropdown
  import PetalComponents.Field
  import PetalComponents.Form
  import PetalComponents.Icon
  import PetalComponents.Table
  import Phoenix.HTML.Form

  alias Phoenix.LiveView.JS

  def render(assigns) do
    index = order_index(assigns.meta.flop, assigns.column[:field])
    direction = order_direction(assigns.meta.flop.order_directions, index)

    assigns =
      assigns
      |> assign(:currently_ordered, index == 0)
      |> assign(:order_direction, direction)
      |> assign(:dropdown_id, "dt-#{String.replace(to_string(assigns.column[:field]), "_", "-")}")

    ~H"""
    <.th class={"align-top #{@column[:class] || ""}"}>
      <div class="relative">
        <%= if @column[:sortable] && !@no_results? do %>
          <div
            id={"#{@dropdown_id}-backdrop"}
            class="hidden fixed inset-0 z-40"
            phx-click={
              JS.hide(
                to: "##{@dropdown_id}-menu",
                transition: {"transition-opacity duration-150", "opacity-100", "opacity-0"}
              )
              |> JS.add_class("hidden opacity-0", to: "##{@dropdown_id}-menu")
              |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@dropdown_id}-menu")
              |> JS.hide(to: "##{@dropdown_id}-backdrop")
            }
          >
          </div>
          <!-- Sort Button with Dropdown -->
          <button
            id={@dropdown_id}
            type="button"
            class={
              [
                "w-full flex items-center gap-x-1 text-sm font-normal",
                # Negative margins to compensate for padding
                "px-3 py-2 -mx-3 -my-2",
                "hover:bg-stone-50 dark:hover:bg-neutral-800 rounded transition-colors",
                "focus:outline-hidden focus:bg-stone-100 dark:focus:bg-neutral-700",
                if(@currently_ordered,
                  do: "text-stone-800 dark:text-white font-medium",
                  else: "text-stone-500 dark:text-neutral-500"
                ),
                if(@column[:align_right], do: "justify-end", else: "text-start")
              ]
            }
            aria-haspopup="menu"
            aria-expanded="false"
            aria-label={"Sort #{get_label(@column)}"}
            phx-click={
              JS.hide(
                to: "[id$='-menu']:not(##{@dropdown_id}-menu)",
                transition: {"transition-opacity duration-150", "opacity-100", "opacity-0"}
              )
              |> JS.add_class("opacity-0 hidden", to: "[id$='-menu']:not(##{@dropdown_id}-menu)")
              |> JS.show(to: "##{@dropdown_id}-menu")
              |> JS.remove_class("hidden opacity-0", to: "##{@dropdown_id}-menu")
              |> JS.toggle_attribute({"aria-expanded", "true", "false"})
              |> JS.show(to: "##{@dropdown_id}-backdrop")
            }
          >
            <span>{get_label(@column)}</span>
            <svg
              class="shrink-0 size-3.5"
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="m7 15 5 5 5-5" /><path d="m7 9 5-5 5 5" />
            </svg>
          </button>
          
    <!-- Dropdown Menu -->
          <div
            id={"#{@dropdown_id}-menu"}
            class="absolute top-full left-0 mt-1 w-44 opacity-0 hidden z-50 bg-white rounded-xl shadow-xl dark:bg-neutral-900 border border-stone-200 dark:border-neutral-700"
            role="menu"
            aria-orientation="vertical"
            aria-labelledby={@dropdown_id}
          >
            <div class="p-1">
              <!-- Sort Ascending -->
              <.link
                patch={order_link(@column, @meta, @currently_ordered, :asc, @base_url_params)}
                class={[
                  "w-full flex items-center gap-x-3 py-1.5 px-2 rounded-lg text-[13px] font-normal",
                  "hover:bg-stone-100 disabled:opacity-50 disabled:pointer-events-none",
                  "dark:hover:bg-neutral-800 dark:focus:bg-neutral-800 focus:outline-hidden focus:bg-stone-100",
                  if(@currently_ordered && @order_direction == :asc,
                    do: "text-stone-900 bg-stone-50 dark:text-white dark:bg-neutral-800",
                    else: "text-stone-800 dark:text-neutral-300"
                  )
                ]}
              >
                <.icon name="hero-arrow-up" class="shrink-0 size-3.5" />
                {gettext("Sort ascending")}
              </.link>
              
    <!-- Sort Descending -->
              <.link
                patch={order_link(@column, @meta, @currently_ordered, :desc, @base_url_params)}
                class={[
                  "w-full flex items-center gap-x-3 py-1.5 px-2 rounded-lg text-[13px] font-normal",
                  "hover:bg-stone-100 disabled:opacity-50 disabled:pointer-events-none",
                  "dark:hover:bg-neutral-800 dark:focus:bg-neutral-800 focus:outline-hidden focus:bg-stone-100",
                  if(@currently_ordered && @order_direction == :desc,
                    do: "text-stone-900 bg-stone-50 dark:text-white dark:bg-neutral-800",
                    else: "text-stone-800 dark:text-neutral-300"
                  )
                ]}
              >
                <.icon name="hero-arrow-down" class="shrink-0 size-3.5" />
                {gettext("Sort descending")}
              </.link>

              <%= if @column[:moveable] do %>
                <div class="my-1 border-t border-stone-200 dark:border-neutral-800"></div>
                
    <!-- Move Left -->
                <button
                  type="button"
                  phx-click="move-column"
                  phx-value-field={@column[:field]}
                  phx-value-direction="left"
                  class="w-full flex items-center gap-x-3 py-1.5 px-2 rounded-lg text-[13px] font-normal text-stone-800 hover:bg-stone-100 disabled:opacity-50 disabled:pointer-events-none dark:text-neutral-300 focus:outline-hidden focus:bg-stone-100 dark:hover:bg-neutral-800 dark:focus:bg-neutral-800"
                >
                  <.icon name="hero-arrow-left" class="shrink-0 size-3.5" />
                  {gettext("Move left")}
                </button>
                
    <!-- Move Right -->
                <button
                  type="button"
                  phx-click="move-column"
                  phx-value-field={@column[:field]}
                  phx-value-direction="right"
                  class="w-full flex items-center gap-x-3 py-1.5 px-2 rounded-lg text-[13px] font-normal text-stone-800 hover:bg-stone-100 disabled:opacity-50 disabled:pointer-events-none dark:text-neutral-300 focus:outline-hidden focus:bg-stone-100 dark:hover:bg-neutral-800 dark:focus:bg-neutral-800"
                >
                  <.icon name="hero-arrow-right" class="shrink-0 size-3.5" />
                  {gettext("Move right")}
                </button>
              <% end %>

              <%= if @column[:hideable] != false do %>
                <div class="my-1 border-t border-stone-200 dark:border-neutral-800"></div>
                
    <!-- Hide Column -->
                <button
                  type="button"
                  phx-click="hide-column"
                  phx-value-field={@column[:field]}
                  class="w-full flex items-center gap-x-3 py-1.5 px-2 rounded-lg text-[13px] font-normal text-stone-800 hover:bg-stone-100 disabled:opacity-50 disabled:pointer-events-none dark:text-neutral-300 focus:outline-hidden focus:bg-stone-100 dark:hover:bg-neutral-800 dark:focus:bg-neutral-800"
                >
                  <.icon name="hero-eye-slash" class="shrink-0 size-3.5" />
                  {gettext("Hide in view")}
                </button>
              <% end %>
            </div>
          </div>
        <% else %>
          <!-- Non-sortable column -->
          <div class={[
            "text-sm font-normal text-stone-500 dark:text-neutral-500",
            if(@column[:align_right], do: "text-right", else: "")
          ]}>
            {get_label(@column)}
          </div>
        <% end %>
        
    <!-- Filters -->
        <%= if @column[:filterable] && (@filtered? || !@no_results?) do %>
          <.inputs_for :let={f2} field={@filter_form[:filters]}>
            <%= if input_value(f2, :field) == @column.field do %>
              <.field field={f2[:field]} type="hidden" />

              <div class="flex items-center gap-2 mt-2">
                <%= case @column[:type] do %>
                  <% :integer -> %>
                    <.number_input
                      form={f2}
                      field={:value}
                      phx-debounce="200"
                      placeholder={get_filter_placeholder(input_value(f2, :op))}
                      class="!text-xs !py-1 !px-2 !rounded-lg !border-stone-200 dark:!border-neutral-700"
                    />
                  <% :float -> %>
                    <.number_input
                      form={f2}
                      field={:value}
                      phx-debounce="200"
                      placeholder={get_filter_placeholder(input_value(f2, :op))}
                      class="!text-xs !py-1 !px-2 !rounded-lg !border-stone-200 dark:!border-neutral-700"
                      step={@column[:step] || 1}
                    />
                  <% :boolean -> %>
                    <.select
                      form={f2}
                      field={:value}
                      options={[{"True", true}, {"False", false}]}
                      prompt="-"
                      class="!text-xs !py-1 !px-2 !rounded-lg !border-stone-200 dark:!border-neutral-700"
                      size="sm"
                    />
                  <% :select -> %>
                    <.select
                      form={f2}
                      field={:value}
                      options={@column[:options]}
                      prompt={@column[:prompt] || "-"}
                      class="!text-xs !py-1 !px-2 !rounded-lg !border-stone-200 dark:!border-neutral-700"
                      size="sm"
                    />
                  <% _ -> %>
                    <.search_input
                      form={f2}
                      field={:value}
                      phx-debounce="200"
                      placeholder={get_filter_placeholder(input_value(f2, :op))}
                      class="!text-xs !py-1 !px-2 !rounded-lg !border-stone-200 dark:!border-neutral-700"
                    />
                <% end %>

                <%= if length(@column[:filterable]) > 1 do %>
                  <.dropdown js_lib="alpine_js">
                    <:trigger_element>
                      <button
                        type="button"
                        class="inline-flex items-center justify-center p-1.5 rounded-lg hover:bg-stone-100 dark:hover:bg-neutral-700 focus:outline-hidden"
                      >
                        <.icon
                          name="hero-funnel"
                          class="w-3.5 h-3.5 text-stone-500 dark:text-neutral-400"
                        />
                      </button>
                    </:trigger_element>
                    <div class="p-3 font-normal normal-case">
                      <.form_field
                        type="radio_group"
                        form={f2}
                        field={:op}
                        label={gettext("Filter type")}
                        options={@column.filterable |> Enum.map(&{get_filter_placeholder(&1), &1})}
                      />
                    </div>
                  </.dropdown>
                <% else %>
                  {PhoenixHTMLHelpers.Form.hidden_input(f2, :op)}
                <% end %>
              </div>
            <% end %>
          </.inputs_for>
        <% end %>
      </div>
    </.th>
    """
  end

  defp get_label(column) do
    case column[:label] do
      nil ->
        PhoenixHTMLHelpers.Form.humanize(column.field)

      label ->
        label
    end
  end

  defp order_link(column, meta, _currently_ordered, target_direction, base_url_params) do
    params =
      Map.merge(base_url_params, %{
        order_by: [column.field, column[:order_by_backup] || :inserted_at],
        order_directions: [target_direction, :desc]
      })

    PetalProWeb.DataTable.build_url_query(meta, params)
  end

  defp order_index(%Flop{order_by: nil}, _), do: nil

  defp order_index(%Flop{order_by: order_by}, field) do
    Enum.find_index(order_by, &(&1 == field))
  end

  defp order_direction(_, nil), do: nil
  defp order_direction(nil, _), do: :asc
  defp order_direction(directions, index), do: Enum.at(directions, index)

  defp get_filter_placeholder(op) do
    op_map()[op]
  end

  # List of op options
  def op_map do
    %{
      ==: gettext("Equals"),
      !=: gettext("Not equal"),
      =~: gettext("Search (case insensitive)"),
      empty: gettext("Is empty"),
      not_empty: gettext("Not empty"),
      <=: gettext("Less than or equals"),
      <: gettext("Less than"),
      >=: gettext("Greater than or equals"),
      >: gettext("Greater than"),
      in: gettext("Search in"),
      contains: gettext("Contains"),
      like: gettext("Search (case sensitive)"),
      like_and: gettext("Search (case sensitive) (and)"),
      like_or: gettext("Search (case sensitive) (or)"),
      ilike: gettext("Search (case insensitive)"),
      ilike_and: gettext("Search (case insensitive) (and)"),
      ilike_or: gettext("Search (case insensitive) (or)")
    }
  end
end
