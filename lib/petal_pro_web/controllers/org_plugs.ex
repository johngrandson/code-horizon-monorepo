defmodule PetalProWeb.OrgPlugs do
  @moduledoc false
  use PetalProWeb, :verified_routes
  use Gettext, backend: PetalProWeb.Gettext

  import Phoenix.Controller
  import Plug.Conn

  def assign_org_data(conn, _opts) do
    org_slug = conn.params["org_slug"]
    orgs = PetalPro.Orgs.list_orgs(conn.assigns.current_user)
    current_org = Enum.find(orgs, &(&1.slug == org_slug))

    if org_slug && !current_org do
      conn
      |> put_flash(:error, gettext("You do not have permission to access this page."))
      |> redirect(to: ~p"/app/orgs")
      |> halt()
    else
      current_membership = org_slug && PetalPro.Orgs.get_membership!(conn.assigns.current_user, org_slug)

      conn
      |> assign(:orgs, orgs)
      |> assign(:current_membership, current_membership)
      |> assign(:current_org, current_org)
    end
  end

  # Must be run after :assign_org_data
  def require_org_member(conn, _opts) do
    membership = conn.assigns.current_membership

    if membership do
      conn
    else
      conn
      |> put_flash(:error, gettext("You do not have permission to access this page."))
      |> redirect(to: PetalProWeb.Helpers.home_path(conn.assigns.current_user))
      |> halt()
    end
  end

  # Must be run after :assign_org_data
  def require_org_admin(conn, _opts) do
    membership = conn.assigns.current_membership

    if membership && membership.role == :admin do
      conn
    else
      conn
      |> put_flash(:error, gettext("You do not have permission to access this page."))
      |> redirect(to: PetalProWeb.Helpers.home_path(conn.assigns.current_user))
      |> halt()
    end
  end
end
