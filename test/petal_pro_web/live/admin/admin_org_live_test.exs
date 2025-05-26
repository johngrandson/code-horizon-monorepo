defmodule PetalProWeb.AdminOrgLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.OrgsFixtures
  import Phoenix.LiveViewTest

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  defp create_org(_) do
    org = org_fixture()
    %{org: org}
  end

  describe "Index" do
    setup [:register_and_sign_in_admin, :create_org]

    test "lists all orgs", %{conn: conn, org: org} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/orgs")

      assert html =~ "Organizations"
      assert html =~ org.name
    end

    test "saves new org", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/orgs")

      assert index_live |> element("a", "New Organization") |> render_click() =~
               "New Organization"

      assert_patch(index_live, ~p"/admin/orgs/new")

      assert index_live
             |> form("#org-form", org: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#org-form", org: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/orgs")

      assert html =~ "Organization successfully created"
      assert html =~ "some name"
    end

    test "updates org in listing", %{conn: conn, org: org} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/orgs")

      assert index_live
             |> element("a[href='/admin/orgs/#{org.slug}/edit']", "Edit")
             |> render_click() =~
               "Edit Organization"

      assert_patch(index_live, ~p"/admin/orgs/#{org}/edit")

      assert index_live
             |> form("#org-form", org: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#org-form", org: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/orgs")

      assert html =~ "Organization successfully updated"
      assert html =~ "some updated name"
    end

    test "deletes org in listing", %{conn: conn, org: org} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/orgs")

      assert index_live |> element("a[phx-value-id=#{org.id}]", "Delete") |> render_click()
      refute has_element?(index_live, "a[phx-value-id=#{org.id}]")
    end
  end

  describe "Show" do
    setup [:register_and_sign_in_admin, :create_org]

    test "displays org", %{conn: conn, org: org} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/orgs/#{org}")

      assert html =~ "Organization"
      assert html =~ org.name
    end

    test "updates org within modal", %{conn: conn, org: org} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/orgs/#{org}")

      assert show_live |> element("span", "Edit") |> render_click() =~
               "Edit Organization"

      assert_patch(show_live, ~p"/admin/orgs/#{org}/show/edit")

      assert show_live
             |> form("#org-form", org: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#org-form", org: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/orgs/#{org}")

      assert html =~ "Organization successfully updated"
      assert html =~ "some updated name"
    end

    test "adds a new membership and deletes it again", %{conn: conn, user: user} do
      org = PetalPro.OrgsFixtures.org_fixture()

      {:ok, show_live, _html} = live(conn, ~p"/admin/orgs/#{org}")

      assert show_live |> element("button", "Add User") |> render_click() =~
               "Add User"

      {:ok, show_live, html} =
        show_live
        |> form("#membership-form", membership: %{user_id: user.id, role: "admin"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/orgs/#{org}")

      assert html =~ "Membership successfully created"
      assert html =~ user.name

      # edit
      membership = PetalPro.Repo.last(PetalPro.Orgs.Membership)

      assert show_live |> element(~s{[phx-click="membership_edit"][phx-value-id=#{membership.id}]}) |> render_click() =~
               "Role"

      {:ok, show_live, html} =
        show_live
        |> form("#membership-form", membership: %{role: "member"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/orgs/#{org}")

      assert html =~ "Membership successfully updated"

      # delete

      assert show_live |> element(~s{[phx-click="membership_delete"][phx-value-id=#{membership.id}]}) |> render_click() =~
               "Membership successfully deleted"

      refute has_element?(show_live, "a#delete-#{membership.id}")
    end
  end
end
