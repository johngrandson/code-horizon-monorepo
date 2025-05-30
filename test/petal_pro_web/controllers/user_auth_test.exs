defmodule PetalProWeb.UserAuthTest do
  use PetalProWeb.ConnCase, async: true

  import PetalPro.AccountsFixtures

  alias PetalPro.Accounts
  alias PetalProWeb.UserAuth

  @remember_me_cookie "_petal_pro_web_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, PetalProWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: confirmed_user_fixture(), conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user token in the session", %{conn: conn, user: user} do
      conn = UserAuth.log_in_user(conn, user)
      assert token = get_session(conn, :user_token)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/app"
      assert Accounts.get_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn = conn |> put_session(:to_be_removed, "value") |> UserAuth.log_in_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, user: user} do
      conn = conn |> put_session(:user_return_to, "/hello") |> UserAuth.log_in_user(user)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, user: user} do
      conn = conn |> fetch_cookies() |> UserAuth.log_in_user(user, %{"remember_me" => "true"})
      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
    end

    test "won't login a suspended user", %{conn: conn, user: user} do
      user = Map.put(user, :is_suspended, true)

      conn =
        conn
        |> fetch_flash()
        |> UserAuth.log_in_user(user)

      assert redirected_to(conn) == ~p"/auth/sign-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "There is a problem with your account. Please contact support."
    end

    test "won't login a deleted user", %{conn: conn, user: user} do
      user = Map.put(user, :is_deleted, true)

      conn =
        conn
        |> fetch_flash()
        |> UserAuth.log_in_user(user)

      assert redirected_to(conn) == ~p"/auth/sign-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "There is a problem with your account. Please contact support."
    end

    test "redirects to user_return_to if stored in session", %{conn: conn, user: user} do
      conn =
        conn
        |> put_session(:user_return_to, "/hello")
        |> UserAuth.log_in_user(user)

      assert redirected_to(conn) == "/hello"
    end

    test "redirects to org invites if an invite is pending", %{conn: conn, user: user} do
      org = PetalPro.OrgsFixtures.org_fixture()
      PetalPro.OrgsFixtures.invitation_fixture(org, %{email: user.email})
      conn = UserAuth.log_in_user(conn, user)
      assert redirected_to(conn) == "/app/users/org-invitations"
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, user_token)
        |> put_req_cookie(@remember_me_cookie, user_token)
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Accounts.get_user_by_session_token(user_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      PetalProWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAuth.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UserAuth.log_out_user()
      refute get_session(conn, :user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)
      conn = conn |> put_session(:user_token, user_token) |> UserAuth.fetch_current_user([])
      assert conn.assigns.current_user.id == user.id
      refute conn.assigns.current_user.current_impersonator
    end

    test "authenticates user from cookies", %{conn: conn, user: user} do
      logged_in_conn =
        conn |> fetch_cookies() |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UserAuth.fetch_current_user([])

      assert get_session(conn, :user_token) == user_token
      assert conn.assigns.current_user.id == user.id
      refute conn.assigns.current_user.current_impersonator
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _ = Accounts.generate_user_session_token(user)
      conn = UserAuth.fetch_current_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_user
    end
  end

  describe "fetch_impersonator_user/2" do
    test "returns impersonator user if impersonating as admin", %{conn: conn, user: user} do
      admin = admin_fixture()
      admin_token = Accounts.generate_user_session_token(admin)

      conn =
        conn
        |> put_session(:user_token, admin_token)
        |> put_session(:impersonator_user_id, user.id)
        |> UserAuth.fetch_current_user([])
        |> UserAuth.fetch_impersonator_user([])

      assert conn.assigns.current_user.id == admin.id
      assert conn.assigns.current_user.current_impersonator.id == user.id
    end

    test "does not impersonate when user is not authorized", %{conn: conn, user: user} do
      conn = conn |> put_session(:impersonator_user_id, user.id) |> UserAuth.fetch_impersonator_user([])
      refute Map.has_key?(conn.assigns, :current_user)
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, user: user} do
      conn = conn |> assign(:current_user, user) |> UserAuth.redirect_if_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/app"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn = UserAuth.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
    test "redirects if user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/auth/sign-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "You must sign in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :user_return_to)
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      conn = conn |> assign(:current_user, user) |> UserAuth.require_authenticated_user([])
      refute conn.halted
      refute conn.status
    end

    test "it redirects if user is authenticated but not confirmed", %{conn: conn} do
      unconfirmed_user = user_fixture()

      conn =
        conn
        |> fetch_flash()
        |> assign(:current_user, unconfirmed_user)
        |> UserAuth.require_authenticated_user([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/auth/confirm"
    end
  end
end
