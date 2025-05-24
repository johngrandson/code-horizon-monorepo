defmodule PetalProWeb.EditOrgLiveTest do
  use PetalProWeb.ConnCase, async: true

  import PetalPro.OrgsFixtures
  import Phoenix.LiveViewTest

  alias PetalPro.Orgs.Org
  alias PetalPro.Repo

  describe "when an admin using valid params" do
    setup :register_and_sign_in_admin

    test "can edit and update an org", %{conn: conn, org: org, user: _user} do
      edit_org_path = ~p"/app/org/#{org.slug}/edit"
      current_slug = org.slug
      {:ok, view, _html} = live(conn, edit_org_path)

      new_name = "Something new"

      {:ok, _view, html} =
        view
        |> form("form", org: %{name: new_name})
        |> render_submit()
        |> follow_redirect(conn, edit_org_path)

      assert html =~ new_name
      assert html =~ "Organization updated"

      org = Repo.last(Org)
      assert org.name == new_name
      assert org.slug == current_slug
    end
  end

  describe "when an admin using invalid params tries to edit an org" do
    setup :register_and_sign_in_admin

    test "it shows errors", %{conn: conn, org: org, user: _user} do
      {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/edit")

      html_response =
        view
        |> form("form")
        |> render_change(%{org: %{name: "d"}})

      assert html_response =~ "should be at least 2"
    end
  end

  describe "when a member tries to edit an org" do
    setup :register_and_sign_in_user

    test "it redirects", %{conn: conn, org: _org, user: user} do
      new_org = org_fixture()
      membership_fixture(new_org, user, :member)

      assert {:error, {:redirect, %{flash: %{"error" => "You do not have permission to access this page."}}}} =
               live(conn, ~p"/app/org/#{new_org.slug}/edit")
    end
  end
end
