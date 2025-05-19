defmodule PetalProWeb.UserResetPasswordLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.AccountsFixtures
  import Phoenix.LiveViewTest

  alias PetalPro.Accounts

  setup do
    user = user_fixture()

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_reset_password_instructions(user, url)
      end)

    %{token: token, user: user}
  end

  describe "Reset password page" do
    test "renders reset password with valid token", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/auth/reset-password/#{token}")

      assert html =~ "Reset password"
    end

    test "renders reset password when signed in", %{conn: conn, token: token, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/auth/reset-password/#{token}")

      assert html =~ "Reset password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      {:error, {:redirect, to}} = live(conn, ~p"/auth/reset-password/invalid")

      assert to == %{
               flash: %{"error" => "Reset password link is invalid or it has expired."},
               to: ~p"/"
             }
    end

    test "renders errors for invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password/#{token}")

      result =
        lv
        |> element("#reset_password_form")
        |> render_change(user: %{"password" => "xxx", "confirmation_password" => "xxxy"})

      assert result =~ "should be at least 8 character"
      assert result =~ "does not match password"
    end
  end

  describe "Reset Password" do
    test "resets password once", %{conn: conn, token: token, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password/#{token}")

      {:ok, conn} =
        lv
        |> form("#reset_password_form",
          user: %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/auth/sign-in")

      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password reset successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password/#{token}")

      result =
        lv
        |> form("#reset_password_form",
          user: %{
            "password" => "2short",
            "password_confirmation" => "does not match"
          }
        )
        |> render_submit()

      assert result =~ "Reset password"
      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
    end
  end

  describe "Reset password navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password/#{token}")

      {:ok, conn} =
        lv
        |> element(~s|main a:fl-contains("Sign in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/auth/sign-in")

      assert conn.resp_body =~ "Sign in"
    end

    test "redirects to password reset page when the Register button is clicked", %{
      conn: conn,
      token: token
    } do
      {:ok, lv, _html} = live(conn, ~p"/auth/reset-password/#{token}")

      {:ok, conn} =
        lv
        |> element(~s|main a:fl-contains("Register")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/auth/register")

      assert conn.resp_body =~ "Register"
    end
  end
end
