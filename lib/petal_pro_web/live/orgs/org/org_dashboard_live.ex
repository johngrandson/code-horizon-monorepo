defmodule PetalProWeb.OrgDashboardLive do
  @moduledoc """
  Show a dashboard for a single org. Current user must be a member of the org.
  """
  use PetalProWeb, :live_view

  import PetalProWeb.OrgLayoutComponent

  alias PetalPro.Orgs.Membership

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: socket.assigns.current_org.name,
        total_members: Membership.org_members_count(socket.assigns.current_org),
        health_status: :up
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.org_layout
      current_page={:org_dashboard}
      current_user={@current_user}
      current_org={@current_org}
      current_membership={@current_membership}
      socket={@socket}
    >
      <.container class="py-4">
        <main id="content" class="pb-10 sm:pb-16">
          <!-- Overlay User Profile -->
          <div class="relative before:absolute before:-bottom-14 before:start-0 before:-z-1 before:w-full before:h-14">
            <div class="max-w-5xl mx-auto px-2 sm:px-5 xl:px-0">
              <div class="flex flex-col items-center sm:flex-row sm:items-center sm:gap-5 pt-2 lg:pt-5 pb-2 md:pb-4 mb-4">
                <div class="shrink-0 mb-4 sm:mb-0">
                  <div class="relative shrink-0 size-20.5 sm:w-20.5 sm:h-20.5">
                    <div class="shrink-0 size-20.5 sm:w-20.5 sm:h-20.5 rounded-full object-cover">
                      <%= if @current_org.avatar_url do %>
                        <img
                          class="rounded-full object-cover"
                          src={@current_org.avatar_url}
                          alt={@current_org.name}
                        />
                        <%= if @current_org.is_enterprise do %>
                          <.pro_badge class="top-17" />
                        <% end %>
                      <% else %>
                        <div class="rounded-full bg-gray-700"></div>
                      <% end %>
                    </div>
                  </div>
                </div>
                <div class="grow text-center sm:text-left">
                  <h1 class="text-2xl md:text-3xl font-semibold dark:text-white">
                    {@current_org.name}
                  </h1>

                  <p class="mt-2 text-sm text-gray-500 dark:text-neutral-400">
                    <.icon name="hero-link" class="w-4 h-4" />
                    {@current_org.slug}
                  </p>
                </div>
              </div>
            </div>
          </div>
          <!-- End Overlay User Profile -->

          <!-- Stats Grid -->
          <div class="grid grid-cols-2 px-5 md:grid-cols-4 gap-2 md:gap-4 mb-4">
            <!-- Card -->
            <a
              class="group p-4 bg-white border border-gray-200 rounded-xl hover:-translate-y-0.5 focus:outline-hidden focus:-translate-y-0.5 transition dark:bg-neutral-900 dark:border-neutral-700"
              href="#"
            >
              <div class="flex gap-x-3">
                <div class="grow">
                  <h2 class="text-xs text-gray-600 dark:text-neutral-400">
                    {gettext("Total members")}
                  </h2>
                  <p class="text-xl font-semibold text-gray-800 dark:text-white">
                    {@total_members}
                  </p>
                </div>
                <.icon name="hero-users" class="shrink-0 size-6 text-gray-500 dark:text-neutral-400" />
              </div>
              <span class="mt-3 inline-flex items-center gap-x-1 text-sm text-teal-600 font-medium group-hover:text-teal-500 group-focus:text-teal-500">
                {gettext("View members")}
                <svg
                  class="shrink-0 size-4"
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
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </span>
            </a>
            <!-- End Card -->

            <!-- Card -->
            <a
              class="group p-4 bg-white border border-gray-200 rounded-xl hover:-translate-y-0.5 focus:outline-hidden focus:-translate-y-0.5 transition dark:bg-neutral-900 dark:border-neutral-700"
              href="#"
            >
              <div class="flex gap-x-3">
                <div class="grow">
                  <h2 class="text-xs text-gray-600 dark:text-neutral-400">
                    {gettext("Active Modules")}
                  </h2>
                  <p class="text-xl font-semibold text-gray-800 dark:text-white">
                    5
                  </p>
                </div>
                <.icon name="hero-cube" class="shrink-0 size-6 text-gray-500 dark:text-neutral-400" />
              </div>
              <span class="mt-3 inline-flex items-center gap-x-1 text-sm text-teal-600 font-medium group-hover:text-teal-500 group-focus:text-teal-500">
                {gettext("View modules")}
                <svg
                  class="shrink-0 size-4"
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
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </span>
            </a>
            <!-- End Card -->

            <!-- Card -->
            <a
              class="group p-4 bg-white border border-gray-200 rounded-xl hover:-translate-y-0.5 focus:outline-hidden focus:-translate-y-0.5 transition dark:bg-neutral-900 dark:border-neutral-700"
              href="#"
            >
              <div class="flex gap-x-3">
                <div class="grow">
                  <h2 class="text-xs text-gray-600 dark:text-neutral-400">
                    {gettext("Health Status")}
                  </h2>
                  <p class="text-xl font-semibold text-gray-800 dark:text-white">
                    <%= if @health_status == :up do %>
                      {gettext("Up")}
                    <% else %>
                      {gettext("Down")}
                    <% end %>
                  </p>
                </div>
                <%= if @health_status == :up do %>
                  <.icon name="hero-bolt" class="shrink-0 size-6 text-gray-500 dark:text-neutral-400" />
                <% else %>
                  <.icon
                    name="hero-bolt-slash"
                    class="shrink-0 size-6 text-gray-500 dark:text-neutral-400"
                  />
                <% end %>
              </div>
              <span class="mt-3 inline-flex items-center gap-x-1 text-sm text-teal-600 font-medium group-hover:text-teal-500 group-focus:text-teal-500">
                {gettext("View status")}
                <svg
                  class="shrink-0 size-4"
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
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </span>
            </a>
            <!-- End Card -->

    <!-- Card -->
            <a
              class="group p-4 bg-white border border-gray-200 rounded-xl hover:-translate-y-0.5 focus:outline-hidden focus:-translate-y-0.5 transition dark:bg-neutral-900 dark:border-neutral-700"
              href="#"
            >
              <div class="flex gap-x-3">
                <div class="grow">
                  <h2 class="text-xs text-gray-600 dark:text-neutral-400">
                    {gettext("Total tickets")}
                  </h2>
                  <p class="text-xl font-semibold text-gray-800 dark:text-white">
                    1h 51m
                  </p>
                </div>
                <svg
                  class="shrink-0 size-6 text-gray-500 dark:text-neutral-400"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M2 12a10 10 0 1 1 10 10" /><path d="m2 22 10-10" /><path d="M8 22H2v-6" />
                </svg>
              </div>
              <span class="mt-3 inline-flex items-center gap-x-1 text-sm text-teal-600 font-medium group-hover:text-teal-500 group-focus:text-teal-500">
                {gettext("View tickets")}
                <svg
                  class="shrink-0 size-4"
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
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </span>
            </a>
            <!-- End Card -->
          </div>
          <!-- End Stats Grid -->

          <div class="max-w-5xl mx-auto px-2 sm:px-5 xl:px-0 pb-10">
            <!-- Card Grid Group -->
            <div class="grid md:grid-cols-8 gap-y-5 md:gap-y-0 md:gap-x-4">
              <div class="md:col-span-4 lg:col-span-4">
                <!-- Card -->
                <div class="p-4 h-full relative flex flex-col justify-between bg-white border border-gray-200 rounded-xl dark:bg-neutral-900 dark:border-neutral-700">
                  <div class="flex justify-between items-center gap-x-2">
                    <h2 class="font-semibold text-lg text-gray-800 dark:text-neutral-200">
                      {gettext("Profile setup")}
                    </h2>
                  </div>

                  <div class="mt-3 w-40">
                    <h4 class="mb-1 text-sm text-gray-800 dark:text-neutral-200">2 of 4 completed</h4>
                    <div class="grid grid-cols-4 gap-x-1.5">
                      <div class="bg-teal-600  h-2 flex-auto rounded-sm"></div>
                      <div class="bg-teal-600  h-2 flex-auto rounded-sm"></div>
                      <div class="bg-teal-600 opacity-30 h-2 flex-auto rounded-sm"></div>
                      <div class="bg-teal-600 opacity-30 h-2 flex-auto rounded-sm"></div>
                    </div>
                  </div>

                  <p class="mt-3 text-sm text-gray-600 dark:text-neutral-400">
                    Your profile needs to be at least
                    <span class="font-semibold text-gray-800 dark:text-neutral-200">
                      50% complete
                    </span>
                    to be publicly visible.
                  </p>

                  <div class="mt-3 md:mt-5">
                    <div class="space-y-1.5">
                      <div class="py-2 px-2.5 flex justify-between items-center gap-x-3 bg-gray-100 rounded-lg dark:bg-neutral-800">
                        <!-- Icon -->
                        <span class="size-5 flex shrink-0 justify-center items-center bg-teal-600 text-white rounded-full dark:bg-teal-500">
                          <svg
                            class="shrink-0 size-3.5"
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M20 6 9 17l-5-5"></path>
                          </svg>
                        </span>
                        <!-- End Icon -->

                  <!-- Content -->
                        <div class="grow">
                          <div class="flex justify-between items-center gap-x-1.5">
                            <div class="grow">
                              <s class="text-sm text-gray-400 dark:text-neutral-500">
                                Download desktop app
                              </s>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="py-1.5 px-2 inline-flex items-center gap-x-1 text-xs rounded-md border border-gray-200 bg-white text-gray-800 shadow-2xs hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-50 dark:bg-neutral-600 dark:border-neutral-700 dark:text-neutral-300 dark:hover:bg-neutral-500 dark:focus:bg-neutral-500"
                                disabled
                              >
                                Download
                              </button>
                            </div>
                          </div>
                        </div>
                        <!-- End Content -->
                      </div>

                      <div class="py-2 px-2.5 flex justify-between items-center gap-x-3 bg-gray-100 rounded-lg dark:bg-neutral-800">
                        <span class="size-5 flex shrink-0 justify-center items-center text-gray-800 dark:text-neutral-200">
                          <svg
                            class="shrink-0 size-4"
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z" />
                            <path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2" />
                            <path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2" />
                            <path d="M10 6h4" />
                            <path d="M10 10h4" />
                            <path d="M10 14h4" />
                            <path d="M10 18h4" />
                          </svg>
                        </span>
                        <!-- End Icon -->

                  <!-- Content -->
                        <div class="grow">
                          <div class="flex justify-between items-center gap-x-1.5">
                            <div class="grow">
                              <span class="text-sm text-gray-800 dark:text-white">
                                Provide company details
                              </span>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="py-1.5 px-2 inline-flex items-center gap-x-1 text-xs rounded-md border border-gray-200 bg-white text-gray-800 shadow-2xs hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-50 dark:bg-neutral-600 dark:border-neutral-700 dark:text-neutral-300 dark:hover:bg-neutral-500 dark:focus:bg-neutral-500"
                              >
                                Add now
                              </button>
                            </div>
                          </div>
                        </div>
                        <!-- End Content -->
                      </div>
                      <!-- End Item -->

                <!-- Item -->
                      <div class="py-2 px-2.5 flex justify-between items-center gap-x-3 bg-gray-100 rounded-lg dark:bg-neutral-800">
                        <!-- Icon -->
                        <span class="size-5 flex shrink-0 justify-center items-center bg-teal-600 text-white rounded-full dark:bg-teal-500">
                          <svg
                            class="shrink-0 size-3.5"
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M20 6 9 17l-5-5"></path>
                          </svg>
                        </span>
                        <!-- End Icon -->

                  <!-- Content -->
                        <div class="grow">
                          <div class="flex justify-between items-center gap-x-1.5">
                            <div class="grow">
                              <s class="text-sm text-gray-400 dark:text-neutral-500">
                                Invite 5 talents
                              </s>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="py-1.5 px-2 inline-flex items-center gap-x-1 text-xs rounded-md border border-gray-200 bg-white text-gray-800 shadow-2xs hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-50 dark:bg-neutral-600 dark:border-neutral-700 dark:text-neutral-300 dark:hover:bg-neutral-500 dark:focus:bg-neutral-500"
                                disabled
                              >
                                Invite
                              </button>
                            </div>
                          </div>
                        </div>
                        <!-- End Content -->
                      </div>
                      <!-- End Item -->

                <!-- Item -->
                      <div class="py-2 px-2.5 flex justify-between items-center gap-x-3 bg-gray-100 rounded-lg dark:bg-neutral-800">
                        <!-- Icon -->
                        <span class="size-5 flex shrink-0 justify-center items-center text-gray-800 dark:text-neutral-200">
                          <svg
                            class="shrink-0 size-4"
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z" />
                            <path d="M8 10v4" />
                            <path d="M12 10v2" />
                            <path d="M16 10v6" />
                          </svg>
                        </span>
                        <!-- End Icon -->

                  <!-- Content -->
                        <div class="grow">
                          <div class="flex justify-between items-center gap-x-1.5">
                            <div class="grow">
                              <span class="text-sm text-gray-800 dark:text-white">
                                Add projects
                              </span>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="py-1.5 px-2 inline-flex items-center gap-x-1 text-xs rounded-md border border-gray-200 bg-white text-gray-800 shadow-2xs hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-50 dark:bg-neutral-600 dark:border-neutral-700 dark:text-neutral-300 dark:hover:bg-neutral-500 dark:focus:bg-neutral-500"
                              >
                                Add now
                              </button>
                            </div>
                          </div>
                        </div>
                        <!-- End Content -->
                      </div>
                      <!-- End Item -->
                    </div>
                    <!-- End List -->
                  </div>
                </div>
              </div>

              <div class="md:col-span-4 lg:col-span-4">
                <!-- Sales Stats Card -->
                <div class="size-full flex flex-col bg-white border border-gray-200 shadow-2xs rounded-xl dark:bg-neutral-900 dark:border-neutral-700">
                  <!-- Header -->
                  <div class="p-5 pb-3 flex justify-between items-center">
                    <h2 class="inline-block font-semibold text-lg text-gray-800 dark:text-neutral-200">
                      Total sales
                    </h2>
                    
    <!-- Calendar Dropdown -->
                    <div class="hs-dropdown [--auto-close:inside] inline-flex">
                      <button
                        id="hs-pro-dnic"
                        type="button"
                        class="p-2 inline-flex items-center text-xs font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-2xs hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-50 dark:bg-neutral-800 dark:border-neutral-700 dark:text-neutral-300 dark:hover:bg-neutral-700 dark:focus:bg-neutral-700"
                        aria-haspopup="menu"
                        aria-expanded="false"
                        aria-label="Dropdown"
                      >
                        <svg
                          class="shrink-0 me-2 size-3.5"
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
                          <rect width="18" height="18" x="3" y="4" rx="2" ry="2" /><line
                            x1="16"
                            x2="16"
                            y1="2"
                            y2="6"
                          /><line x1="8" x2="8" y1="2" y2="6" /><line x1="3" x2="21" y1="10" y2="10" /><path d="M8 14h.01" /><path d="M12 14h.01" /><path d="M16 14h.01" /><path d="M8 18h.01" /><path d="M12 18h.01" /><path d="M16 18h.01" />
                        </svg>
                        Today
                        <svg
                          class="shrink-0 ms-1.5 size-3.5"
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
                          <path d="m6 9 6 6 6-6" />
                        </svg>
                      </button>

                      <div
                        class="hs-dropdown-menu hs-dropdown-open:opacity-100 w-79.5 transition-[opacity,margin] duration opacity-0 hidden z-50 bg-white rounded-xl shadow-xl dark:bg-neutral-900"
                        role="menu"
                        aria-orientation="vertical"
                        aria-labelledby="hs-pro-dnic"
                      >
                        
    <!-- Calendar -->
                        <div class="p-3 space-y-0.5">
                          <!-- Months -->
                          <div class="grid grid-cols-5 items-center gap-x-3 mx-1.5 pb-3">
                            <!-- Prev Button -->
                            <div class="col-span-1">
                              <button
                                type="button"
                                class="size-8 flex justify-center items-center text-gray-800 hover:bg-gray-100 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-400 dark:hover:bg-neutral-800 dark:focus:bg-neutral-800"
                                aria-label="Previous"
                              >
                                <svg
                                  class="shrink-0 size-4"
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
                                  <path d="m15 18-6-6 6-6" />
                                </svg>
                              </button>
                            </div>
                            <!-- End Prev Button -->

                <!-- Month / Year -->
                            <div class="col-span-3 flex justify-center items-center gap-x-1">
                              <div class="relative">
                                <select
                                  data-hs-select='{
                        "placeholder": "Select month",
                        "toggleTag": "<button type=\"button\" aria-expanded=\"false\"></button>",
                        "toggleClasses": "hs-select-disabled:pointer-events-none hs-select-disabled:opacity-50 relative flex text-nowrap w-full cursor-pointer text-start font-medium text-gray-800 hover:text-blue-600 focus:outline-hidden focus:text-blue-600 before:absolute before:inset-0 before:z-1 dark:text-neutral-200 dark:hover:text-blue-500 dark:focus:text-blue-500",
                        "dropdownClasses": "mt-2 z-50 w-32 max-h-72 p-1 space-y-0.5 bg-white border border-gray-200 rounded-lg shadow-lg overflow-hidden overflow-y-auto [&::-webkit-scrollbar]:w-2 [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-track]:bg-gray-100 [&::-webkit-scrollbar-thumb]:bg-gray-300 dark:[&::-webkit-scrollbar-track]:bg-neutral-700 dark:[&::-webkit-scrollbar-thumb]:bg-neutral-500 dark:bg-neutral-900 dark:border-neutral-700",
                        "optionClasses": "p-2 w-full text-sm text-gray-800 cursor-pointer hover:bg-gray-100 rounded-lg focus:outline-hidden focus:bg-gray-100 dark:bg-neutral-900 dark:hover:bg-neutral-800 dark:text-neutral-200 dark:focus:bg-neutral-800",
                        "optionTemplate": "<div class=\"flex justify-between items-center w-full\"><span data-title></span><span class=\"hidden hs-selected:block\"><svg class=\"shrink-0 size-3.5 text-gray-800 dark:text-neutral-200\" xmlns=\"http:.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><polyline points=\"20 6 9 17 4 12\"/></svg></span></div>"
                      }'
                                  class="hidden"
                                >
                                  <option value="0">January</option>
                                  <option value="1">February</option>
                                  <option value="2">March</option>
                                  <option value="3">April</option>
                                  <option value="4">May</option>
                                  <option value="5">June</option>
                                  <option value="6" selected>July</option>
                                  <option value="7">August</option>
                                  <option value="8">September</option>
                                  <option value="9">October</option>
                                  <option value="10">November</option>
                                  <option value="11">December</option>
                                </select>
                              </div>

                              <span class="text-gray-800 dark:text-neutral-200">/</span>

                              <div class="relative">
                                <select
                                  data-hs-select='{
                        "placeholder": "Select year",
                        "toggleTag": "<button type=\"button\" aria-expanded=\"false\"></button>",
                        "toggleClasses": "hs-select-disabled:pointer-events-none hs-select-disabled:opacity-50 relative flex text-nowrap w-full cursor-pointer text-start font-medium text-gray-800 hover:text-blue-600 focus:outline-hidden focus:text-blue-600 before:absolute before:inset-0 before:z-1 dark:text-neutral-200 dark:hover:text-blue-500 dark:focus:text-blue-500",
                        "dropdownClasses": "mt-2 z-50 w-20 max-h-72 p-1 space-y-0.5 bg-white border border-gray-200 rounded-lg shadow-lg overflow-hidden overflow-y-auto [&::-webkit-scrollbar]:w-2 [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-track]:bg-gray-100 [&::-webkit-scrollbar-thumb]:bg-gray-300 dark:[&::-webkit-scrollbar-track]:bg-neutral-700 dark:[&::-webkit-scrollbar-thumb]:bg-neutral-500 dark:bg-neutral-900 dark:border-neutral-700",
                        "optionClasses": "p-2 w-full text-sm text-gray-800 cursor-pointer hover:bg-gray-100 rounded-lg focus:outline-hidden focus:bg-gray-100 dark:bg-neutral-900 dark:hover:bg-neutral-800 dark:text-neutral-200 dark:focus:bg-neutral-800",
                        "optionTemplate": "<div class=\"flex justify-between items-center w-full\"><span data-title></span><span class=\"hidden hs-selected:block\"><svg class=\"shrink-0 size-3.5 text-gray-800 dark:text-neutral-200\" xmlns=\"http:.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><polyline points=\"20 6 9 17 4 12\"/></svg></span></div>"
                      }'
                                  class="hidden"
                                >
                                  <option selected>2023</option>
                                  <option>2024</option>
                                  <option>2025</option>
                                  <option>2026</option>
                                  <option>2027</option>
                                </select>
                              </div>
                            </div>
                            <!-- End Month / Year -->

                <!-- Next Button -->
                            <div class="col-span-1 flex justify-end">
                              <button
                                type="button"
                                class=" size-8 flex justify-center items-center text-gray-800 hover:bg-gray-100 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-400 dark:hover:bg-neutral-800 dark:focus:bg-neutral-800"
                                aria-label="Next"
                              >
                                <svg
                                  class="shrink-0 size-4"
                                  width="24"
                                  height="24"
                                  viewBox="0 0 24 24"
                                  fill="none"
                                  stroke="currentColor"
                                  stroke-width="2"
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                >
                                  <path d="m9 18 6-6-6-6" />
                                </svg>
                              </button>
                            </div>
                            <!-- End Next Button -->
                          </div>
                          <!-- Months -->

              <!-- Weeks -->
                          <div class="flex pb-1.5">
                            <span class="m-px w-10 block text-center text-sm text-gray-500 dark:text-neutral-500">
                              Mo
                            </span>
                            <span class="m-px w-10 block text-center text-sm text-gray-500 dark:text-neutral-500">
                              Tu
                            </span>
                            <span class="m-px w-10 block text-center text-sm text-gray-500 dark:text-neutral-500">
                              We
                            </span>
                            <span class="m-px w-10 block text-center text-sm text-gray-500 dark:text-neutral-500">
                              Th
                            </span>
                            <span class="m-px w-10 block text-center text-sm text-gray-500 dark:text-neutral-500">
                              Fr
                            </span>
                            <span class="m-px w-10 block text-center text-sm text-gray-500 dark:text-neutral-500">
                              Sa
                            </span>
                            <span class="m-px w-10 block text-center text-sm text-gray-500 dark:text-neutral-500">
                              Su
                            </span>
                          </div>
                          <!-- Weeks -->

              <!-- Days -->
                          <div class="flex">
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                                disabled
                              >
                                26
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                                disabled
                              >
                                27
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                                disabled
                              >
                                28
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                                disabled
                              >
                                29
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                                disabled
                              >
                                30
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                1
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                2
                              </button>
                            </div>
                          </div>
                          <!-- Days -->

              <!-- Days -->
                          <div class="flex">
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                3
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                4
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                5
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                6
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                7
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                8
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                9
                              </button>
                            </div>
                          </div>
                          <!-- Days -->

              <!-- Days -->
                          <div class="flex">
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                10
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                11
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                12
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                13
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                14
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                15
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                16
                              </button>
                            </div>
                          </div>
                          <!-- Days -->

              <!-- Days -->
                          <div class="flex">
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                17
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                18
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                19
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center bg-blue-600 border-[1.5px] border-transparent text-sm font-medium text-white hover:border-blue-600 rounded-full dark:bg-blue-500 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:hover:border-neutral-700"
                              >
                                20
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                21
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                22
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                23
                              </button>
                            </div>
                          </div>
                          <!-- Days -->

              <!-- Days -->
                          <div class="flex">
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                24
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                25
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                26
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                27
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                28
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                29
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                30
                              </button>
                            </div>
                          </div>
                          <!-- Days -->

              <!-- Days -->
                          <div class="flex">
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 rounded-full hover:border-blue-600 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:border-blue-600 focus:text-blue-600 dark:text-neutral-200 dark:hover:border-blue-500 dark:hover:text-blue-500 dark:focus:border-blue-500 dark:focus:text-blue-500"
                              >
                                31
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 hover:border-blue-600 hover:text-blue-600 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-200 dark:hover:border-neutral-500 dark:focus:bg-neutral-700"
                                disabled
                              >
                                1
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 hover:border-blue-600 hover:text-blue-600 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-200 dark:hover:border-neutral-500 dark:focus:bg-neutral-700"
                                disabled
                              >
                                2
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 hover:border-blue-600 hover:text-blue-600 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-200 dark:hover:border-neutral-500 dark:focus:bg-neutral-700"
                                disabled
                              >
                                3
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 hover:border-blue-600 hover:text-blue-600 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-200 dark:hover:border-neutral-500 dark:focus:bg-neutral-700"
                                disabled
                              >
                                4
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 hover:border-blue-600 hover:text-blue-600 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-200 dark:hover:border-neutral-500 dark:focus:bg-neutral-700"
                                disabled
                              >
                                5
                              </button>
                            </div>
                            <div>
                              <button
                                type="button"
                                class="m-px size-10 flex justify-center items-center border-[1.5px] border-transparent text-sm text-gray-800 hover:border-blue-600 hover:text-blue-600 rounded-full disabled:opacity-50 disabled:pointer-events-none focus:outline-hidden focus:bg-gray-100 dark:text-neutral-200 dark:hover:border-neutral-500 dark:focus:bg-neutral-700"
                                disabled
                              >
                                6
                              </button>
                            </div>
                          </div>
                          <!-- Days -->
                        </div>
                      </div>
                    </div>
                    <!-- End Calendar Dropdown -->
                  </div>
                  <!-- End Header -->

    <!-- Body -->
                  <div class="h-full pb-5 px-5 space-y-8">
                    <h4 class="text-4xl font-medium text-gray-800 dark:text-neutral-200">
                      <span class="-me-1.5 text-sm align-top text-gray-500 dark:text-neutral-500">
                        $
                      </span>
                      43,350
                    </h4>
                    
    <!-- List Group -->
                    <ul class="space-y-3">
                      <!-- List Item -->
                      <li class="flex flex-wrap justify-between items-center gap-x-2">
                        <div>
                          <div class="flex items-center gap-x-2">
                            <div class="inline-block size-2.5 bg-blue-600 rounded-sm"></div>
                            <h2 class="inline-block align-middle text-gray-500 dark:text-neutral-400">
                              Store sales
                            </h2>
                          </div>
                        </div>
                        <div>
                          <span class="text-gray-800 dark:text-neutral-200">
                            $51,392
                          </span>
                          <span class="ms-3 min-w-20 inline-block text-gray-600 dark:text-neutral-400">
                            <svg
                              class="inline-block align-middle size-4 text-teal-500"
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
                              <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" /><polyline points="16 7 22 7 22 13" />
                            </svg>
                            38.2%
                          </span>
                        </div>
                      </li>
                      <!-- End List Item -->

      <!-- List Item -->
                      <li class="flex flex-wrap justify-between items-center gap-x-2">
                        <div>
                          <div class="flex items-center gap-x-2">
                            <div class="inline-block size-2.5 bg-purple-600 rounded-sm"></div>
                            <h2 class="inline-block align-middle text-gray-500 dark:text-neutral-400">
                              Online sales
                            </h2>
                          </div>
                        </div>
                        <div>
                          <span class="text-gray-800 dark:text-neutral-200">
                            $46,420
                          </span>
                          <span class="ms-3 min-w-20 inline-block text-gray-600 dark:text-neutral-400">
                            <svg
                              class="inline-block align-middle size-4 text-teal-500"
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
                              <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" /><polyline points="16 7 22 7 22 13" />
                            </svg>
                            5.9%
                          </span>
                        </div>
                      </li>
                      <!-- End List Item -->

      <!-- List Item -->
                      <li class="flex flex-wrap justify-between items-center gap-x-2">
                        <div>
                          <div class="flex items-center gap-x-2">
                            <div class="inline-block size-2.5 bg-gray-300 rounded-sm dark:bg-neutral-500">
                            </div>
                            <h2 class="inline-block align-middle text-gray-500 dark:text-neutral-400">
                              Others
                            </h2>
                          </div>
                        </div>
                        <div>
                          <span class="text-gray-800 dark:text-neutral-200">
                            $39,539
                          </span>
                          <span class="ms-3 min-w-20 inline-block text-gray-600 dark:text-neutral-400">
                            <svg
                              class="inline-block align-middle size-4 text-red-500"
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
                              <polyline points="22 17 13.5 8.5 8.5 13.5 2 7" /><polyline points="16 17 22 17 22 11" />
                            </svg>
                            3.1%
                          </span>
                        </div>
                      </li>
                      <!-- End List Item -->
                    </ul>
                  </div>
                  <!-- End Body -->

                  <!-- Footer -->
                    <!-- Apex Line Chart -->
                  <div
                    id="org-dashboard-chart"
                    phx-hook="OrgDashboardChartHook"
                    class="min-h-[115px] w-full"
                  >
                  </div>
                  <!-- End Footer -->
                </div>
                <!-- End Sales Stats Card -->
              </div>
            </div>
          </div>
        </main>

        <script src="https://cdnjs.cloudflare.com/ajax/libs/apexcharts/3.44.0/apexcharts.min.js">
        </script>
      </.container>
    </.org_layout>
    """
  end
end
