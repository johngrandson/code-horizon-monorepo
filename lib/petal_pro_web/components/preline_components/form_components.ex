defmodule PrelineComponents.FormComponents do
  @moduledoc false
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :title, :string, default: nil
  attr :confirm_text, :string, default: "Confirm"
  attr :cancel_text, :string, default: "Cancel"
  attr :confirm_class, :string, default: "bg-green-600 hover:bg-green-700"
  attr :cancel_class, :string, default: ""
  attr :max_width, :string, default: "lg", values: ["sm", "md", "lg", "xl", "full"]
  attr :live_action, :any, default: nil
  attr :show_on, :list, default: []
  attr :close_on_click_away, :boolean, default: true
  attr :close_on_escape, :boolean, default: true
  attr :on_cancel, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def preline_dialog_modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={show_modal(@id)} phx-remove={hide_modal(@id)} class="hidden" {@rest}>
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 z-[60] bg-neutral-900/60 dark:bg-neutral-900/80 transition-opacity"
        aria-hidden="true"
        phx-click={@on_cancel}
      >
      </div>
      <div
        class="fixed inset-0 z-[70] overflow-y-auto"
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
      >
        <div class="flex min-h-full items-center justify-center p-4 sm:p-0">
          <div
            id={"#{@id}-container"}
            class={"bg-white dark:bg-neutral-800 rounded-xl shadow-xl max-w-full mx-auto transition-all transform #{modal_max_width(@max_width)} dark:border dark:border-neutral-700"}
            phx-click-away={@on_cancel}
          >
            <%= if @title do %>
              <div class="py-3 px-5 flex justify-between items-center border-b border-stone-200 dark:border-neutral-700">
                <h3 id={"#{@id}-title"} class="font-medium text-stone-800 dark:text-white">
                  {@title}
                </h3>
                <button
                  type="button"
                  class="flex justify-center items-center size-7 text-stone-500 hover:text-stone-700 rounded-lg border border-transparent hover:bg-stone-100 dark:text-neutral-500 dark:hover:bg-neutral-700"
                  phx-click={@on_cancel}
                  aria-label="Close"
                >
                  <svg
                    class="size-4"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M18 6 6 18" /><path d="m6 6 12 12" />
                  </svg>
                </button>
              </div>
            <% end %>
            <div class="p-5">{render_slot(@inner_block)}</div>
            <div class="px-5 py-4 flex justify-end gap-x-2 border-t border-stone-200 dark:border-neutral-700">
              <button
                type="button"
                class={"py-2 px-3 text-sm font-medium rounded-lg border border-stone-200 bg-white text-stone-800 hover:bg-stone-50 dark:bg-neutral-800 dark:border-neutral-700 dark:text-neutral-200 #{@cancel_class}"}
                phx-click={@on_cancel}
              >
                {@cancel_text}
              </button>
              <button
                type="button"
                class={"py-2 px-3 text-sm font-medium rounded-lg border-transparent bg-green-600 text-white hover:bg-green-700 #{@confirm_class}"}
                phx-click={JS.push("save")}
              >
                {@confirm_text}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :help_text, :string, default: nil
  attr :class, :string, default: ""
  attr :disabled, :boolean, default: false
  attr :rest, :global

  def preline_text_input(assigns) do
    ~H"""
    <div class={@class}>
      <label
        for={"preline_#{@id}"}
        class="block mb-2 text-sm font-medium text-stone-800 dark:text-neutral-200"
      >
        {@label}
      </label>
      <input
        id={"preline_#{@id}"}
        type="text"
        disabled={@disabled}
        value={@value}
        class="py-1.5 px-3 block w-full border-stone-200 rounded-lg text-sm text-stone-800 focus:border-green-600 focus:ring-green-600 dark:bg-neutral-800 dark:border-neutral-700 dark:text-neutral-200"
        placeholder={@placeholder}
        {@rest}
      />
      <%= if @help_text do %>
        <p class="mt-1.5 text-xs text-stone-500 dark:text-neutral-500">{@help_text}</p>
      <% end %>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :options, :list, default: []
  attr :selected, :string, default: ""
  attr :help_text, :string, default: nil
  attr :viewport_id, :string, default: nil
  attr :name, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :string, default: ""
  attr :rest, :global

  def preline_select_input(assigns) do
    select_config = %{
      "placeholder" => "Select option...",
      "toggleTag" => "<button type=\"button\" aria-expanded=\"false\"></button>",
      "toggleClasses" =>
        "hs-select-disabled:pointer-events-none relative py-1.5 px-4 pe-9 w-full cursor-pointer bg-white border border-stone-200 rounded-lg text-start text-sm text-stone-800 focus:ring-2 focus:ring-green-600 dark:bg-neutral-800 dark:border-neutral-700 dark:text-neutral-200",
      "dropdownClasses" => "mt-2 z-50 w-full min-w-36 max-h-72 p-1 bg-white rounded-xl shadow-xl dark:bg-neutral-900",
      "optionClasses" =>
        "hs-selected:bg-stone-100 dark:hs-selected:bg-neutral-800 py-2 px-4 w-full text-sm text-stone-800 cursor-pointer hover:bg-stone-100 rounded-lg dark:text-neutral-200",
      "optionTemplate" =>
        "<div class=\"flex justify-between items-center w-full\"><span data-title></span><span class=\"hidden hs-selected:block\"><svg class=\"size-3.5 text-stone-800 dark:text-neutral-200\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><polyline points=\"20 6 9 17 4 12\"/></svg></span></div>"
    }

    select_config =
      if assigns.viewport_id, do: Map.put(select_config, "viewport", "##{assigns.viewport_id}"), else: select_config

    assigns = assign(assigns, :select_config_json, Jason.encode!(select_config))

    ~H"""
    <div class={@class}>
      <label class="block mb-2 text-sm font-medium text-stone-800 dark:text-neutral-200">
        {@label}
      </label>
      <div class="relative">
        <select id={"preline_#{@id}"} data-hs-select={@select_config_json} class="hidden" {@rest}>
          <option value="">Choose</option>
          <%= for option <- @options do %>
            <option
              value={if is_tuple(option), do: elem(option, 0), else: option}
              selected={
                if is_tuple(option), do: elem(option, 0) == @selected, else: option == @selected
              }
            >
              {if is_tuple(option), do: elem(option, 1), else: option}
            </option>
          <% end %>
        </select>
        <div class="absolute top-1/2 end-2.5 -translate-y-1/2">
          <svg
            class="size-3.5 text-stone-500"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="m7 15 5 5 5-5" /><path d="m7 9 5-5 5 5" />
          </svg>
        </div>
      </div>
      <%= if @help_text do %>
        <p class="mt-1.5 text-xs text-stone-500 dark:text-neutral-500">{@help_text}</p>
      <% end %>
    </div>
    """
  end

  # Funções auxiliares
  defp modal_max_width(size) do
    case size do
      "xs" -> "max-w-xs"
      "sm" -> "max-w-sm"
      "md" -> "max-w-md"
      "lg" -> "max-w-lg"
      "xl" -> "max-w-xl"
      "2xl" -> "max-w-2xl"
      "3xl" -> "max-w-3xl"
      "4xl" -> "max-w-4xl"
      "5xl" -> "max-w-5xl"
      "6xl" -> "max-w-6xl"
      "7xl" -> "max-w-7xl"
      _ -> size
    end
  end

  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-container")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-bg", transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"})
    |> JS.hide(
      to: "##{id}-container",
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end
end
