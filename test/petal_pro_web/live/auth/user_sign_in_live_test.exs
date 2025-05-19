defmodule PetalProWeb.UserLoginLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Sign in page" do
    test "renders sign in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/auth/sign-in")

      assert html =~ "Sign in"
      assert html =~ "Register"
      assert html =~ "Forgot your password?"
    end

    test "redirects if already signed in", %{conn: conn} do
      user = user_fixture()

      result =
        conn
        |> log_in_user(user)
        |> live(~p"/auth/sign-in")
        |> follow_redirect(conn, PetalProWeb.Helpers.home_path(user))

      assert {:ok, _conn} = result
    end
  end

  describe "user sign in" do
    test "redirects if user signs in with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/auth/sign-in")

      form =
        form(lv, "#sign_in_form", user: %{email: user.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == PetalProWeb.Helpers.home_path(user)
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/auth/sign-in")

      form =
        form(lv, "#sign_in_form", user: %{email: "test@email.com", password: "123456", remember_me: true})

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/auth/sign-in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/sign-in")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|a:fl-contains("Register")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/auth/register")

      assert login_html =~ "Register"
    end

    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/auth/sign-in")

      {:ok, conn} =
        lv
        |> element(~s{a:fl-contains('Forgot your password?')})
        |> render_click()
        |> follow_redirect(conn, ~p"/auth/reset-password")

      assert conn.resp_body =~ "Forgot your password?"
    end
  end
end
