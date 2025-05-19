defmodule PetalProApi.SessionControllerTest do
  use PetalProWeb.ConnCase, async: true

  import PetalPro.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /api/session" do
    test "with no credentials user can't login", %{conn: conn} do
      conn = post(conn, ~p"/api/sign-in", email: nil, password: nil)
      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end

    test "with invalid password user cant login", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/sign-in",
          email: user.email,
          password: "wrongpass"
        )

      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end

    test "with valid password user can login", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/sign-in",
          email: user.email,
          password: valid_user_password()
        )

      assert %{
               "token" => "" <> _,
               "token_type" => "bearer"
             } = json_response(conn, 200)
    end
  end
end
