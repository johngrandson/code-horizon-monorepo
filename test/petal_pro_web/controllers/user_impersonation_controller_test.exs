defmodule PetalProWeb.UserImpersonationControllerTest do
  use PetalProWeb.ConnCase, async: true

  import PetalPro.AccountsFixtures

  setup do
    impersonator_fixture()
  end

  describe "POST /auth/impersonate" do
    test "logged in user is has no impersonator_user_id", %{
      conn: conn,
      admin_user: admin_user
    } do
      conn = log_in_user(conn, admin_user)

      assert get_session(conn, :user_token)
      refute get_session(conn, :impersonator_user_id)
    end

    test "impersonated user has impersonator_user_id", %{
      conn: conn,
      user: user,
      admin_user: admin_user
    } do
      conn =
        conn
        |> log_in_user(admin_user)
        |> post(~p"/auth/impersonate?id=#{user.id}")

      assert redirected_to(conn) == "/app"

      current_user = PetalPro.Accounts.get_user_by_session_token(get_session(conn, :user_token))
      assert current_user.id == user.id
    end

    test "can't impersonate if you're not an admin", %{
      conn: conn,
      user: user,
      admin_user: admin_user
    } do
      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/auth/impersonate", id: admin_user.id)

      assert redirected_to(conn) == "/"
      assert get_session(conn, :user_token)
    end

    test "admin can't impersonate another admin", %{
      conn: conn,
      user: user,
      admin_user: admin_user
    } do
      {:ok, user} = PetalPro.Accounts.update_user_as_admin(user, %{role: :admin})

      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/auth/impersonate", id: admin_user.id)

      assert redirected_to(conn) == "/"
      assert get_session(conn, :user_token)
      refute get_session(conn, :impersonator_user_id)
    end
  end

  describe "DELETE /auth/impersonator" do
    test "restores impersonated user", %{conn: conn, user: user, admin_user: admin_user} do
      conn =
        conn
        |> impersonate_user(admin_user, user)
        |> delete(~p"/auth/impersonate")

      assert redirected_to(conn) == "/admin/users"
      assert get_session(conn, :user_token)
      refute get_session(conn, :impersonator_user_id)
    end

    test "succeeds even if the user is not impersonated", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> delete(~p"/auth/impersonate")

      assert redirected_to(conn) == "/"
      assert get_session(conn, :user_token)
      refute get_session(conn, :impersonator_user_id)
    end

    test "redirects if the user is not signed in", %{conn: conn} do
      conn = delete(conn, ~p"/auth/impersonate")
      assert redirected_to(conn) == "/auth/sign-in"
      refute get_session(conn, :user_token)
    end
  end
end
