defmodule PetalProWeb.UserForgotPasswordLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.AccountsFixtures
  import Phoenix.LiveViewTest

  alias PetalPro.Accounts
  alias PetalPro.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/auth/reset-password")

      assert html =~ "Forgot your password?"
      assert html =~ "Register"
      assert html =~ "Sign in"
    end

    test "redirects if already signed in", %{conn: conn} do
      user = user_fixture()

      result =
        conn
        |> log_in_user(user)
        |> live(~p"/auth/reset-password")
        |> follow_redirect(conn, PetalProWeb.Helpers.home_path(user))

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{user: user_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", user: %{"email" => user.email})
        |> render_submit()
        |> follow_redirect(conn, "/auth/sign-in")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", user: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/auth/sign-in")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.UserToken) == []
    end
  end
end
