defmodule PetalProWeb.Components.DashboardComponents do
  @moduledoc """
  A set of components for showing stats in a dashboard.
  """
  use Phoenix.Component
  use PetalComponents

  import PetalProWeb.Components.Charts

  def dashboard_panel(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:heading, fn -> nil end)

    ~H"""
    <div class={[
      "bg-white rounded-lg relative border border-gray-200 dark:shadow-3xl dark:border-gray-700 dark:bg-gray-800",
      @class
    ]}>
      <%= if @heading do %>
        <div class="border-b border-gray-200 dark:border-gray-700">
          <.h5 class="px-5 pt-4">{@heading}</.h5>
        </div>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def dashboard_stat(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:stat, fn -> nil end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:icon, fn -> nil end)
      |> assign_new(:chart_event, fn -> nil end)
      |> assign_new(:chart_datasets, fn -> [] end)
      |> assign_new(:chart_labels, fn -> [] end)
      |> assign_new(:percentage_change, fn -> nil end)
      |> assign_new(:empty?, fn -> false end)
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(
          icon
          class
          label
          stat
          chart_datasets
          percentage_change
        )a)
      end)

    ~H"""
    <div
      class={[
        "p-5 overflow-hidden bg-white rounded-lg border border-gray-200 dark:shadow-3xl dark:border-gray-700 dark:bg-gray-800 sm:p-6",
        @class
      ]}
      {@extra_assigns}
    >
      <div class="">
        <div class="flex flex-col">
          <div class="inline-flex">
            <%= if @icon do %>
              <div class="p-3 mr-5 rounded-md bg-sky-100 dark:bg-sky-700">
                <.icon name={@icon} class={["w-8 h-8 text-sky-700 dark:text-gray-900", @class]} />
              </div>
            <% end %>
            <div class="flex flex-col overflow-hidden">
              <dt class="text-sm font-medium text-gray-600 truncate dark:text-gray-200">
                {@label}
              </dt>
              <dd class="flex items-baseline gap-1 overflow-hidden text-3xl font-semibold text-gray-900 sm:gap-2 dark:text-gray-100">
                {@stat}
                <.percentage_change percentage={@percentage_change} />
                <span class="text-sm font-light text-gray-500 truncate dark:text-gray-400">
                  vs last period
                </span>
              </dd>
            </div>
          </div>
        </div>
        <div class="pt-5">
          <.no_data :if={@empty} class="h-16 text-sm" />
          <.chart_js
            :if={not @empty}
            class="w-full h-16"
            event={@chart_event}
            options={
              %{
                type: "line",
                options: %{
                  maintainAspectRatio: false,
                  responsive: true,
                  tension: 0.4,
                  pointRadius: 0,
                  scales: %{
                    y: %{
                      grid: %{
                        display: false,
                        drawBorder: false,
                        drawTicks: false
                      },
                      ticks: %{
                        display: false
                      }
                    },
                    x: %{
                      grid: %{
                        display: false,
                        drawBorder: false
                      },
                      ticks: %{
                        display: false
                      }
                    }
                  },
                  plugins: %{
                    legend: %{
                      display: false
                    }
                  },
                  interaction: %{
                    intersect: false,
                    mode: "nearest"
                  }
                }
              }
            }
          />
        </div>
      </div>
    </div>
    """
  end

  def percentage_change(%{percentage: nil} = assigns), do: ~H""

  def percentage_change(%{percentage: percentage} = assigns) when percentage >= 0 do
    ~H"""
    <span class="flex items-baseline ml-2 text-sm font-semibold text-emerald-600">
      <svg
        class="self-center shrink-0 w-5 h-5 text-emerald-500"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 20 20"
        fill="currentColor"
        aria-hidden="true"
      >
        <path
          fill-rule="evenodd"
          d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z"
          clip-rule="evenodd"
        />
      </svg>
      {@percentage}%
    </span>
    """
  end

  def percentage_change(%{percentage: percentage} = assigns) when percentage < 0 do
    ~H"""
    <span class="flex items-baseline text-sm font-semibold text-red-600">
      <svg
        class="self-center shrink-0 w-5 h-5 text-red-500"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 20 20"
        fill="currentColor"
        aria-hidden="true"
      >
        <path
          fill-rule="evenodd"
          d="M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z"
          clip-rule="evenodd"
        />
      </svg>
      {@percentage}%
    </span>
    """
  end

  attr :heading, :string, required: true, doc: "The heading of the panel."
  attr :chart_event, :string, required: true, doc: "The event to push to the live view socket."
  attr :empty, :boolean, default: false, doc: "Whether the data is empty."
  attr :class, :string, default: "", doc: "The class for the panel."
  attr :graph_type, :string, default: "bar", doc: "The type of chart."

  def dashboard_graph(assigns) do
    ~H"""
    <.dashboard_panel heading={@heading} class={@class}>
      <.no_data :if={@empty} />
      <.chart_js
        :if={not @empty}
        class="p-5 h-96"
        event={@chart_event}
        options={
          %{
            type: "#{@graph_type}",
            options: %{
              maintainAspectRatio: false,
              layout: %{
                padding: %{
                  top: 12,
                  bottom: 16,
                  left: 20,
                  right: 20
                }
              },
              tension: 0.4,
              scales: %{
                y: %{
                  grid: %{
                    drawBorder: false
                  },
                  ticks: %{
                    maxTicksLimit: 5,
                    color: "#9ca3af",
                    font: %{
                      size: 14
                    }
                  }
                },
                x: %{
                  type: "time",
                  time: %{
                    parser: "MM-yyyy",
                    unit: "month",
                    displayFormats: %{
                      month: "MMM"
                    }
                  },
                  ticks: %{
                    color: "#9ca3af",
                    font: %{
                      size: 14
                    }
                  },
                  grid: %{
                    display: false,
                    drawBorder: false
                  }
                }
              },
              plugins: %{
                legend: %{
                  labels: %{
                    color: "#9ca3af",
                    font: %{
                      size: 14
                    }
                  }
                }
              }
            }
          }
        }
      />
    </.dashboard_panel>
    """
  end

  attr :heading, :string, required: true, doc: "The heading of the panel."
  attr :chart_event, :string, required: true, doc: "The event for LiveView data loading."
  attr :class, :string, default: "", doc: "The class for the panel."
  attr :empty, :boolean, default: false, doc: "Whether the data is empty."

  def dashboard_donut(assigns) do
    ~H"""
    <.dashboard_panel class="col-span-4 md:col-span-2" heading={@heading}>
      <.no_data :if={@empty} />
      <.chart_js
        :if={not @empty}
        class="p-2 mb-5 h-96"
        event={@chart_event}
        options={
          %{
            type: "doughnut",
            options: %{
              responsive: true,
              maintainAspectRatio: true,
              cutout: "80%",
              layout: %{
                padding: %{
                  top: 24,
                  bottom: 24
                }
              },
              scales: %{
                y: %{
                  grid: %{
                    display: false,
                    drawBorder: false,
                    drawTicks: false
                  },
                  ticks: %{
                    display: false,
                    color: "#9ca3af",
                    font: %{
                      size: 14
                    }
                  }
                },
                x: %{
                  grid: %{
                    display: false,
                    drawBorder: false
                  },
                  ticks: %{
                    display: false,
                    color: "#9ca3af",
                    font: %{
                      size: 14
                    }
                  }
                }
              },
              plugins: %{
                legend: %{
                  labels: %{
                    color: "#9ca3af",
                    font: %{
                      size: 14
                    }
                  }
                }
              }
            }
          }
        }
      />
    </.dashboard_panel>
    """
  end

  attr :class, :string, default: "h-96 text-lg", doc: "The class for the panel."

  defp no_data(assigns) do
    ~H"""
    <div class={["flex items-center justify-center", @class]}>
      <p class="font-normal text-gray-400 dark:text-gray-500">
        No data available
      </p>
    </div>
    """
  end
end
