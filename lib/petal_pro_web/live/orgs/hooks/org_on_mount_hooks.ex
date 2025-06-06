defmodule PetalProWeb.OrgOnMountHooks do
  @moduledoc """
  Org related on_mount hooks used by live views. These are used in the router or within a specific live view if need be.
  Docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
  """
  use Gettext, backend: PetalProWeb.Gettext

  import Phoenix.Component
  import Phoenix.LiveView
  import Phoenix.PubSub

  alias PetalPro.Orgs

  @doc """
  Assigns orgs, current membership, and current org for authenticated routes.
  """
  def on_mount(:assign_org_data, params, _session, socket) do
    socket =
      socket
      |> assign_orgs()
      |> assign_current_membership(params)
      |> assign_current_org()
      |> register_multi_org_handlers()

    {:cont, socket}
  end

  def on_mount(:assign_public_org_data, params, _session, socket) do
    socket =
      assign_current_org(socket, :public, params)

    {:cont, socket}
  end

  def on_mount(:require_org_member, _params, _session, socket) do
    if socket.assigns[:current_membership] do
      {:cont, socket}
    else
      socket =
        put_flash(socket, :error, gettext("You do not have permission to access this page."))

      {:halt, redirect(socket, to: PetalProWeb.Helpers.home_path(socket.assigns.current_user))}
    end
  end

  def on_mount(:require_org_admin, _params, _session, socket) do
    if socket.assigns[:current_membership] && socket.assigns.current_membership.role == :admin do
      {:cont, socket}
    else
      previous_url =
        get_connect_info(socket, :peer_data)[:referer] ||
          PetalProWeb.Helpers.home_path(socket.assigns.current_user)

      socket =
        socket
        |> put_flash(:error, gettext("You do not have permission to access this page."))
        |> redirect(to: previous_url)

      {:halt, socket}
    end
  end

  def assign_orgs(socket) do
    assign_new(socket, :orgs, fn ->
      socket.assigns[:current_user] && Orgs.list_orgs(socket.assigns.current_user)
    end)
  end

  defp assign_current_membership(socket, params) do
    assign_new(socket, :current_membership, fn ->
      if params["org_slug"] do
        membership = Orgs.get_membership!(socket.assigns.current_user, params["org_slug"])

        %{membership | org: Orgs.preload_org_module_subscriptions(membership.org)}
      end
    end)
  end

  defp assign_current_org(socket) do
    assign_new(socket, :current_org, fn ->
      membership = socket.assigns.current_membership
      membership && membership.org
    end)
  end

  defp assign_current_org(socket, :public, %{"org_slug" => org_slug}) do
    assign_new(socket, :current_org, fn ->
      Orgs.get_org!(org_slug)
    end)
  end

  defp register_multi_org_handlers(socket) do
    if connected?(socket) do
      user_id = socket.assigns.current_user.id

      for org <- socket.assigns.orgs do
        topic = "user:#{user_id}:org:#{org.id}"
        subscribe(PetalPro.PubSub, topic)
      end
    end

    socket
  end
end
