defmodule PetalProWeb.Admin.UserLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.AccountsFixtures
  import Phoenix.LiveViewTest

  @create_attrs %{name: "some name", email: "some@email.name", password: "some password"}
  @update_attrs %{name: "some updated name", email: "some@updated.email.name", password: "some updated password"}
  @invalid_attrs %{name: nil}

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  describe "Index" do
    setup [:register_and_sign_in_admin, :create_user]

    test "lists all users", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/users")

      assert html =~ "Users"
      assert html =~ user.name
    end

    test "saves new user", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("a", "New User") |> render_click() =~
               "New User"

      assert_patch(index_live, ~p"/admin/users/new")

      assert index_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#user-form", user: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/users")

      assert html =~ "User successfully created"
      assert html =~ "some name"
    end

    test "updates user in listing", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live
             |> element("a[href='/admin/users/#{user.id}/edit']", "Edit")
             |> render_click() =~
               "Edit User"

      assert_patch(index_live, ~p"/admin/users/#{user}/edit")

      assert index_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#user-form", user: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/users")

      assert html =~ "User successfully updated"
      assert html =~ "some updated name"
    end

    test "deletes user in listing", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("button[phx-value-id=#{user.id}]", "Delete") |> render_click()
      refute has_element?(index_live, "a[phx-value-id=#{user.id}]")
    end
  end

  describe "Show" do
    setup [:register_and_sign_in_admin]

    test "displays user", %{conn: conn, user: user} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/users/#{user}")

      assert html =~ "#{user.id}"
      assert html =~ user.name
    end

    test "updates user within modal", %{conn: conn, user: user} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/users/#{user}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit User"

      assert_patch(show_live, ~p"/admin/users/#{user}/show/edit")

      assert show_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#user-form", user: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/users/#{user}")

      assert html =~ "User successfully updated"
      assert html =~ "some updated name"
    end

    test "adds a new membership and deletes it again", %{conn: conn, user: user} do
      org = PetalPro.OrgsFixtures.org_fixture()
      {:ok, show_live, _html} = live(conn, ~p"/admin/users/#{user}")

      assert show_live |> element("button", "Add Membership") |> render_click() =~
               "Add Membership"

      {:ok, show_live, html} =
        show_live
        |> form("#membership-form", membership: %{org_id: org.id, role: "admin"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/users/#{user}")

      assert html =~ "Membership successfully created"
      assert html =~ org.name

      # edit
      membership = PetalPro.Repo.last(PetalPro.Orgs.Membership)

      assert show_live |> element(~s{[phx-click="membership_edit"][phx-value-id=#{membership.id}]}) |> render_click() =~
               "Role"

      {:ok, show_live, html} =
        show_live
        |> form("#membership-form", membership: %{role: "member"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/users/#{user}")

      assert html =~ "Membership successfully updated"

      # delete

      assert show_live |> element(~s{[phx-click="membership_delete"][phx-value-id=#{membership.id}]}) |> render_click() =~
               "Membership successfully deleted"

      refute has_element?(show_live, "a#delete-#{membership.id}")
    end
  end
end
