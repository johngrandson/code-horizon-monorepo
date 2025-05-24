defmodule PetalProWeb.UserOnMountHooks do
  @moduledoc """
  This module houses on_mount hooks used by live views.
  Docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
  """
  use PetalProWeb, :verified_routes
  use Gettext, backend: PetalProWeb.Gettext

  import PetalPro.Events.Modules.Notifications.Broadcaster
  import PetalPro.Notifications
  import Phoenix.Component
  import Phoenix.LiveView

  alias PetalPro.Accounts
  alias PetalPro.Accounts.Permissions
  alias PetalPro.Accounts.User

  # If the page we're loading is the destination for any unread
  # notifications, this hooks into handle_params/3 to mark them as read.
  defp read_relevant_user_notifications(_params, url, %{assigns: %{current_user: %User{} = current_user}} = socket) do
    req_path = url |> URI.parse() |> Map.get(:path)
    read_unread_user_notifications_for_path(current_user, req_path)

    # here you could put the :req_path in assigns, if you like
    {:cont, socket}
  end

  defp read_relevant_user_notifications(_params, _url, socket), do: {:cont, socket}

  def on_mount(:attach_read_relevant_notifications_hook, _params, _session, socket),
    do:
      {:cont,
       Phoenix.LiveView.attach_hook(
         socket,
         :read_relevant_user_notifications,
         :handle_params,
         &read_relevant_user_notifications/3
       )}

  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket =
      socket
      |> maybe_assign_user(session)
      |> maybe_subscribe_to_user_topics()

    if socket.assigns.current_user do
      PetalProWeb.Presence.track(self(), "users", socket.assigns.current_user.id, %{})
      {:cont, socket}
    else
      socket = put_flash(socket, :error, gettext("You must sign in to access this page."))
      {:halt, redirect(socket, to: ~p"/auth/sign-in")}
    end
  end

  def on_mount(:require_confirmed_user, _params, session, socket) do
    socket =
      socket
      |> maybe_assign_user(session)
      |> maybe_subscribe_to_user_topics()

    if socket.assigns.current_user && socket.assigns.current_user.confirmed_at do
      PetalProWeb.Presence.track(self(), "users", socket.assigns.current_user.id, %{})
      {:cont, socket}
    else
      socket =
        put_flash(socket, :error, gettext("You must confirm your email to access this page."))

      {:halt, redirect(socket, to: ~p"/auth/sign-in")}
    end
  end

  def on_mount(:require_admin_user, _params, session, socket) do
    socket =
      socket
      |> maybe_assign_user(session)
      |> maybe_subscribe_to_user_topics()

    if Permissions.can_access_admin_routes?(socket.assigns.current_user) do
      PetalProWeb.Presence.track(self(), "users", socket.assigns.current_user.id, %{})
      {:cont, socket}
    else
      safe_redirect = determine_safe_redirect(socket)

      socket =
        socket
        |> put_flash(:error, gettext("You do not have permission to access this page."))
        |> redirect(to: safe_redirect)

      {:halt, socket}
    end
  end

  def on_mount(:maybe_assign_user, _params, session, socket) do
    {:cont, socket |> maybe_assign_user(session) |> maybe_subscribe_to_user_topics()}
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = socket |> maybe_assign_user(session) |> maybe_subscribe_to_user_topics()

    if socket.assigns.current_user do
      {:halt, redirect(socket, to: "/")}
    else
      {:cont, socket}
    end
  end

  def on_mount(:assign_current_org, _params, _session, socket) do
    {:cont, maybe_assign_current_org(socket)}
  end

  defp maybe_subscribe_to_user_topics(%{assigns: %{current_user: %User{} = user}} = socket) do
    PetalProWeb.Endpoint.subscribe(user_notifications_topic(user.id))
    socket
  end

  defp maybe_subscribe_to_user_topics(socket), do: socket

  defp maybe_assign_user(socket, session) do
    assign_new(socket, :current_user, fn ->
      user = get_user(session["user_token"])

      maybe_assign_impersonator(user, session)
    end)
  end

  defp maybe_assign_impersonator(nil, _session), do: nil

  defp maybe_assign_impersonator(user, session) do
    if session["impersonator_user_id"] do
      impersonator_user = Accounts.get_user!(session["impersonator_user_id"])
      Map.put(user, :current_impersonator, impersonator_user)
    else
      user
    end
  end

  defp maybe_assign_current_org(%{assigns: %{current_user: current_user, current_org: current_org}} = socket) do
    assign(
      socket,
      :current_user,
      Accounts.preload_org_data(current_user, current_org)
    )
  end

  defp maybe_assign_current_org(socket), do: socket

  defp get_user(nil), do: nil
  defp get_user(token), do: Accounts.get_user_by_session_token(token)

  defp determine_safe_redirect(socket) do
    cond do
      socket.assigns[:current_org] && socket.assigns.current_org.slug ->
        "/app/org/#{socket.assigns.current_org.slug}"

      socket.assigns[:current_user] ->
        "/app/orgs"

      !socket.assigns.current_user ->
        "/auth/sign-in"

      true ->
        "/app"
    end
  end
end
