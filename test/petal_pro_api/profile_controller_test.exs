defmodule PetalProApi.ProfileControllerTest do
  use PetalProWeb.ConnCase

  import PetalPro.AccountsFixtures

  @new_name "Booger"
  @new_avatar "https://example.com/different.jpg"
  @new_email "dragon_fin@example.com"

  @current_password "password"
  @new_password "secure_password"

  setup %{conn: conn} do
    user = user_fixture()
    admin_user = admin_fixture()
    other_user = user_fixture()

    {:ok,
     conn: put_req_header(conn, "accept", "application/json"), user: user, admin_user: admin_user, other_user: other_user}
  end

  describe "show" do
    test "show user", %{conn: conn, user: user} do
      conn =
        conn
        |> put_bearer_token(user)
        |> get(~p"/api/user/#{user}")

      assert json_response(conn, 200)
    end

    test "can't show other user", %{conn: conn, user: user, other_user: other_user} do
      conn =
        conn
        |> put_bearer_token(user)
        |> get(~p"/api/user/#{other_user.id}")

      assert json_response(conn, 403)
    end

    test "admin can show other user", %{
      conn: conn,
      admin_user: admin_user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(admin_user)
        |> get(~p"/api/user/#{other_user.id}")

      assert json_response(conn, 200)
    end
  end

  describe "update profile" do
    test "update profile with name and avatar", %{conn: conn, user: user} do
      conn =
        conn
        |> put_bearer_token(user)
        |> patch(~p"/api/user/#{user.id}/update", %{name: @new_name, avatar: @new_avatar})

      assert updated_user = json_response(conn, 200)
      assert updated_user["name"] =~ "Booger"
      assert updated_user["avatar"] =~ "different.jpg"
    end

    test "user can't update profile of other user", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(user)
        |> patch(~p"/api/user/#{other_user.id}/update", %{name: @new_name, avatar: @new_avatar})

      assert json_response(conn, :forbidden)
    end

    test "admin can update profile of other user", %{
      conn: conn,
      admin_user: admin_user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(admin_user)
        |> patch(~p"/api/user/#{other_user.id}/update", %{name: @new_name, avatar: @new_avatar})

      assert updated_user = json_response(conn, 200)
      assert updated_user["name"] =~ "Booger"
      assert updated_user["avatar"] =~ "different.jpg"
    end

    test "can't update profile with email", %{conn: conn, user: user} do
      conn =
        conn
        |> put_bearer_token(user)
        |> patch(~p"/api/user/#{user.id}/update", %{email: @new_email})

      assert user = json_response(conn, 200)
      assert user["email"] != @new_email
    end

    test "can't update profile with password", %{conn: conn, user: user} do
      update_conn =
        conn
        |> put_bearer_token(user)
        |> patch(~p"/api/user/#{user.id}/update", %{password: @new_password})

      assert json_response(update_conn, 200)

      conn = post(conn, ~p"/api/sign-in", email: user.email, password: @new_password)
      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end
  end

  describe "update email" do
    test "update email", %{conn: conn, user: user} do
      conn =
        conn
        |> put_bearer_token(user)
        |> post(~p"/api/user/#{user.id}/request-new-email", %{requested_email: @new_email})

      assert json_response(conn, 200)["message"] =~ "A link to confirm your e-mail"
    end

    test "user can't update email of other user", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(user)
        |> post(~p"/api/user/#{other_user.id}/request-new-email", %{requested_email: @new_email})

      assert json_response(conn, :forbidden)
    end

    test "admin can update email of other user", %{
      conn: conn,
      admin_user: admin_user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(admin_user)
        |> post(~p"/api/user/#{other_user.id}/request-new-email", %{requested_email: @new_email})

      assert json_response(conn, 200)["message"] =~ "A link to confirm your e-mail"
    end
  end

  describe "update password" do
    test "update password", %{conn: conn, user: user} do
      conn =
        conn
        |> put_bearer_token(user)
        |> post(~p"/api/user/#{user.id}/change-password", %{
          current_password: @current_password,
          password: @new_password
        })

      assert json_response(conn, 200)["message"] =~ "Password updated successfully"
    end

    test "user can't update password of other user", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(user)
        |> post(~p"/api/user/#{other_user.id}/change-password", %{
          current_password: @current_password,
          password: @new_password
        })

      assert json_response(conn, :forbidden)
    end

    test "admin can update password of other user", %{
      conn: conn,
      admin_user: admin_user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(admin_user)
        |> post(~p"/api/user/#{other_user.id}/change-password", %{
          current_password: @current_password,
          password: @new_password
        })

      assert json_response(conn, 200)["message"] =~ "Password updated successfully"
    end
  end
end
