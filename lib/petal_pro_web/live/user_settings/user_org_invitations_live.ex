defmodule PetalProWeb.UserOrgInvitationsLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalPro.Events.Modules.Orgs.Subscriber
  import PetalProWeb.UserSettingsLayoutComponent

  alias PetalPro.Accounts
  alias PetalPro.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <.settings_layout current_page={:org_invitations} current_user={@current_user}>
      <div class="space-y-6">
        <div class="flex justify-between items-center">
          <.h2 class="text-xl font-bold text-gray-900 dark:text-white">
            {gettext("Organization Invitations")}
          </.h2>

          <div class="text-sm text-gray-500 dark:text-gray-400">
            <%= if length(@invitations) > 0 do %>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">
                {ngettext(
                  "%{count} pending invitation",
                  "%{count} pending invitations",
                  length(@invitations),
                  count: length(@invitations)
                )}
              </span>
            <% end %>
          </div>
        </div>

        <%= if !is_nil(@current_user.confirmed_at) do %>
          <%= if Util.blank?(@invitations) do %>
            <div class="mt-6 py-12 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 flex flex-col items-center justify-center text-center px-6">
              <div class="rounded-full bg-blue-100 p-3 dark:bg-blue-900 mb-4">
                <.icon name="hero-user-plus" class="w-8 h-8 text-blue-600 dark:text-blue-400" />
              </div>
              <.h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
                {gettext("No Pending Invitations")}
              </.h3>
              <.p class="text-sm text-gray-500 dark:text-gray-400 max-w-md">
                {gettext(
                  "You don't have any pending organization invitations at the moment. When you're invited to join an organization, invitations will appear here"
                )}.
              </.p>
            </div>
          <% else %>
            <.p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
              {gettext(
                "You've been invited to join the following organizations. Accept invitations to collaborate with team members or reject those you don't want to join"
              )}.
            </.p>

            <div class="grid grid-cols-1 md:grid-cols-1 xl:grid-cols-3 gap-6">
              <%= for invitation <- @invitations do %>
                <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow duration-200 overflow-hidden">
                  <div class="h-32 bg-gray-100 dark:bg-gray-700 dark:from-sky-900 dark:via-sky-800 dark:to-sky-700 relative overflow-hidden">
                    <div class="z-0 absolute top-0 end-0">
                      <svg
                        class="w-48 h-56"
                        width="806"
                        height="511"
                        viewBox="0 0 806 511"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <path
                          d="M544.8 -1147.08L1098.08 484L714.167 614.228C692.688 577.817 658.308 547.748 620.707 527.375C561.271 495.163 493.688 482.213 428.253 465.21C391.41 455.641 349.053 438.735 340.625 401.621C335.248 377.942 346.056 354.034 351.234 330.304C364.887 267.777 335.093 198.172 280.434 164.889C266.851 156.619 251.423 149.934 242.315 136.897C214.215 96.6599 268.253 45.1471 263.125 -3.66296C261.266 -21.3099 251.617 -37.124 241.172 -51.463C126.21 -209.336 -87.5388 -248.663 -263.351 -333.763C-314.682 -358.613 -364.939 -389.135 -400.106 -434.021C-435.273 -478.907 -453.106 -540.621 -434.096 -594.389C-408.119 -667.874 -325.246 -703.948 -248.613 -718.248C-171.98 -732.548 -90.1128 -734.502 -23.1788 -774.468C49.5632 -817.9 90.8002 -897.847 147.393 -960.879C175.737 -992.458 208.024 -1019.8 242.465 -1044.52L544.8 -1147.08Z"
                          fill="currentColor"
                          class="fill-gray-300/40 dark:fill-neutral-700/40"
                        />
                        <path
                          d="M726.923 -1341.99L1280.23 288.8L896.3 419.008C874.821 382.608 840.438 352.54 802.834 332.171C743.394 299.964 675.808 287.017 610.369 270.017C573.523 260.45 531.162 243.546 522.736 206.439C517.358 182.765 528.167 158.861 533.345 135.139C547 72.6228 517.203 3.03076 462.545 -30.2462C448.963 -38.5142 433.533 -45.1982 424.425 -58.2323C396.325 -98.4623 450.366 -149.965 445.237 -198.767C443.377 -216.411 433.727 -232.222 423.283 -246.567C308.3 -404.412 94.5421 -443.732 -81.2789 -528.817C-132.615 -553.663 -182.874 -584.179 -218.044 -629.057C-253.214 -673.935 -271.044 -735.64 -252.036 -789.397C-226.058 -862.869 -143.178 -898.936 -66.543 -913.234C10.092 -927.532 91.9721 -929.485 158.905 -969.444C231.652 -1012.86 272.9 -1092.8 329.489 -1155.82C357.834 -1187.39 390.124 -1214.73 424.565 -1239.45L726.923 -1341.99Z"
                          fill="currentColor"
                          class="fill-gray-400/20 dark:fill-neutral-600/30"
                        />
                      </svg>
                    </div>

                    <div class="p-4 flex items-start justify-between">
                      <div class="inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium bg-white backdrop-blur-lg text-gray-600 dark:text-gray-800 shadow-lg">
                        <.icon name="hero-clock" class="w-4 h-4 mr-1.5" />
                        <span>
                          {time_ago(invitation.inserted_at)}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div class="-mt-12 px-4 flex justify-center">
                    <div class="shrink-0">
                      <div class="relative shrink-0 transform transition-transform hover:scale-105">
                        <div class="h-24 w-24 rounded-xl bg-white dark:bg-gray-800 shadow-lg flex items-center justify-center overflow-hidden border-4 border-white dark:border-gray-800">
                          <%= if invitation.org.avatar_url do %>
                            <img
                              src={invitation.org.avatar_url}
                              alt={invitation.org.name}
                              class="h-full w-full object-cover"
                            />
                          <% else %>
                            <div class="flex items-center justify-center w-full h-full bg-gradient-to-br from-primary-50 to-primary-100 dark:from-primary-900 dark:to-primary-800">
                              <span class="text-3xl font-bold text-primary-600 dark:text-primary-400">
                                {String.slice(invitation.org.name, 0, 2) |> String.upcase()}
                              </span>
                            </div>
                          <% end %>
                        </div>
                        <%= if invitation.org.is_enterprise do %>
                          <.pro_badge />
                        <% end %>
                      </div>
                    </div>
                  </div>

                  <div class="p-4 pt-2 text-center">
                    <.h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-1">
                      {invitation.org.name}
                    </.h3>

                    <div class="border-t border-gray-200 dark:border-gray-700 pt-4 pb-2">
                      <.p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                        {gettext(
                          "You've been invited to join this organization. Accept to get access or reject to decline"
                        )}.
                      </.p>

                      <div class="flex items-center gap-3">
                        <.button
                          data-confirm={gettext("Are you sure you want to reject this invitation?")}
                          phx-click="reject_invitation"
                          phx-value-id={invitation.id}
                          color="white"
                          variant="outline"
                          class="flex-1 justify-center"
                        >
                          <.icon name="hero-x-mark" class="w-4 h-4 mr-1.5" />
                          <span>{gettext("Reject")}</span>
                        </.button>

                        <.button
                          phx-click="accept_invitation"
                          phx-value-id={invitation.id}
                          class="flex-1 justify-center"
                        >
                          <span>{gettext("Accept")}</span>
                          <.icon name="hero-check" class="w-4 h-4 ml-1.5" />
                        </.button>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        <% else %>
          <.alert color="warning" class="mt-2 mb-6">
            <div class="flex">
              <div class="flex-shrink-0">
                <.icon name="hero-exclamation-triangle" class="h-5 w-5 text-yellow-400" />
              </div>
              <div class="ml-3">
                <.h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-300">
                  {gettext("Email confirmation required")}
                </.h3>
                <div class="mt-2 text-sm text-yellow-700 dark:text-yellow-200">
                  <.p>
                    {gettext(
                      "You may have pending invitations, but you need to confirm your email address first."
                    )}
                  </.p>
                  <div class="mt-4">
                    <.button
                      phx-click="confirmation_resend"
                      size="sm"
                      color="warning"
                      variant="outline"
                      class="flex items-center"
                    >
                      <.icon name="hero-envelope" class="w-4 h-4 mr-2" />
                      {gettext("Resend confirmation email")}
                    </.button>
                  </div>
                </div>
              </div>
            </div>
          </.alert>

          <div class="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6">
            <div class="flex flex-col items-center text-center">
              <.icon name="hero-envelope-open" class="w-12 h-12 text-gray-400" />
              <.h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">
                {gettext("Check your inbox")}
              </.h3>
              <.p class="mt-1 text-sm text-gray-500 dark:text-gray-400 max-w-sm">
                {gettext(
                  "A confirmation email has been sent to %{email}. Click the link in the email to confirm your account and view your invitations.",
                  email: @current_user.email
                )}
              </.p>
            </div>
          </div>
        <% end %>
      </div>
    </.settings_layout>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_invitations()
      |> register_subscriber()

    {:ok, socket}
  end

  @impl true
  def handle_info({:invitation_deleted, payload}, socket) do
    {:noreply, assign_invitations(socket)}
  end

  @impl true
  def handle_info({:invitation_sent, _payload}, socket) do
    {:noreply, assign_invitations(socket)}
  end

  # Catch-all
  @impl true
  def handle_info(message, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("reject_invitation", %{"id" => id}, socket) do
    invitation = Orgs.reject_invitation!(socket.assigns.current_user, id)

    PetalPro.Logs.log("orgs.reject_invitation", %{
      user: socket.assigns.current_user,
      org_id: invitation.org_id
    })

    # Remove from current list instead of requerying database
    updated_invitations =
      Enum.reject(socket.assigns.invitations, &(&1.id == String.to_integer(id)))

    {:noreply,
     socket
     |> assign(:invitations, updated_invitations)
     |> put_flash(:info, gettext("Invitation rejected successfully"))}
  rescue
    Ecto.InvalidChangesetError ->
      {:noreply, put_flash(socket, :error, gettext("Failed to reject invitation"))}
  end

  @impl true
  def handle_event("accept_invitation", %{"id" => id}, socket) do
    membership = Orgs.accept_invitation!(socket.assigns.current_user, id)

    PetalPro.Logs.log("orgs.accept_invitation", %{
      user: socket.assigns.current_user,
      org_id: membership.org_id,
      metadata: %{
        membership_id: membership.id
      }
    })

    # Remove from current list instead of requerying database
    updated_invitations =
      Enum.reject(socket.assigns.invitations, &(&1.id == String.to_integer(id)))

    {:noreply,
     socket
     |> put_flash(:info, gettext("You've successfully joined %{org_name}", org_name: membership.org.name))
     |> assign(:invitations, updated_invitations)
     |> redirect(to: ~p"/app/org/#{membership.org.slug}")}
  end

  @impl true
  def handle_event("confirmation_resend", _, socket) do
    Accounts.deliver_user_confirmation_instructions(
      socket.assigns.current_user,
      &url(~p"/app/users/settings/confirm-email/#{&1}")
    )

    {:noreply, put_flash(socket, :info, gettext("Confirmation email sent! Please check your inbox."))}
  end

  defp assign_invitations(socket) do
    invitations = Orgs.list_invitations_by_user(socket.assigns.current_user)
    assign(socket, :invitations, invitations)
  end

  defp time_ago(datetime) do
    Timex.from_now(datetime)
  end
end
