defmodule PetalProWeb.Cards do
  @moduledoc false
  use Phoenix.Component
  use PetalComponents

  import PetalComponents.Icon

  attr :title, :string, required: true
  attr :value, :integer, required: true
  attr :icon, :string, required: true
  attr :color, :string, default: "gray"

  def stats_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg">
      <div class="p-5">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <div class={[
              "w-8 h-8 rounded-md flex items-center justify-center",
              color_classes(@color)
            ]}>
              <.icon name={@icon} class="w-5 h-5 text-white" />
            </div>
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
                {@title}
              </dt>
              <dd class="text-lg font-medium text-gray-900 dark:text-white">
                {@value}
              </dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
    """
  end

  slot :header, required: false
  slot :inner_block, required: true

  def custom_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 shadow rounded-lg">
      <div :if={@header != []} class="px-4 py-5 sm:px-6 border-b border-gray-200 dark:border-gray-700">
        <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white">
          {render_slot(@header)}
        </h3>
      </div>
      <div class="px-4 py-5 sm:p-6">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp color_classes(color) do
    case color do
      "blue" -> "bg-blue-500"
      "green" -> "bg-green-500"
      "red" -> "bg-red-500"
      "yellow" -> "bg-yellow-500"
      _ -> "bg-gray-500"
    end
  end
end
