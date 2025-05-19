defmodule PetalProWeb.UserRegistrationLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/auth/register")

      assert html =~ "Register"
      assert html =~ "Sign in"
    end

    test "redirects if already logged in", %{conn: conn} do
      user = user_fixture()

      result =
        conn
        |> log_in_user(user)
        |> live(~p"/auth/register")
        |> follow_redirect(conn, PetalProWeb.Helpers.home_path(user))

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "2short", "password" => "2short"})

      assert result =~ "Register"
      assert result =~ "should be at least 8 character"
    end
  end

  describe "register user" do
    test "creates account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/register")

      email = unique_user_email()
      form = form(lv, "#registration_form", user: valid_user_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)
      user = PetalPro.Repo.last(PetalPro.Accounts.User)
      assert redirected_to(conn) == PetalProWeb.Helpers.home_path(user)

      # Now do a logged in request and assert on the menu
      conn = get(conn, PetalProWeb.Helpers.home_path(user))

      assert html_response(conn, 302)
      assert conn.assigns.flash["info"] =~ "Account created"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/register")

      user = user_fixture(%{email: "test@email.com"})

      lv
      |> form("#registration_form",
        user: %{"email" => user.email, "password" => "valid_password"}
      )
      |> render_submit() =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Sign in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Sign in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/auth/sign-in")

      assert login_html =~ "Sign in"
    end
  end
end
