defmodule PetalProWeb.EditPasswordLiveTest do
  use PetalProWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "when signed in" do
    setup :register_and_sign_in_user

    test "event send_password_reset_email", %{conn: conn, user: _user} do
      {:ok, view, _html} = live(conn, ~p"/app/users/change-password")

      assert view
             |> element("button", "Forgot your password?")
             |> render_click() =~ "You will receive instructions"

      assert_email_sent(subject: "Reset password")
    end
  end

  describe "when signed out" do
    test "can't access the page", %{conn: conn} do
      conn
      |> live(~p"/app/users/edit-email")
      |> assert_route_protected()
    end
  end
end
