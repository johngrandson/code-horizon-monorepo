defmodule PetalProWeb.UserSessionControllerTest do
  use PetalProWeb.ConnCase, async: true

  import PetalPro.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/auth/sign-out")
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
    end

    test "succeeds even if the user is not signed in", %{conn: conn} do
      conn = delete(conn, ~p"/auth/sign-out")
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
    end
  end
end
