defmodule PetalProApi.RegistrationControllerTest do
  use PetalProWeb.ConnCase

  import PetalPro.AccountsFixtures

  @register_user_attrs %{
    email: "dolphin_blade@example.com",
    name: "The Fridge",
    avatar: "https://example.com/some.jpg",
    password: "password"
  }
  @unknown_user_email "unknown@example.com"

  setup %{conn: conn} do
    user = user_fixture()

    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user}
  end

  describe "registration" do
    test "register user", %{conn: conn} do
      conn = post(conn, ~p"/api/register", @register_user_attrs)

      assert registered_user = json_response(conn, 200)["data"]
      assert !registered_user["is_confirmed"]
    end

    test "can't register user twice", %{conn: conn, user: user} do
      user_params = %{name: user.name, email: user.email, password: user.password}
      conn = post(conn, ~p"/api/register", user_params)

      assert %{"email" => [email_error]} = json_response(conn, 422)["errors"]
      assert email_error =~ "has already been taken"
    end
  end

  describe "confirmation" do
    test "send confirmation instructions", %{conn: conn, user: user} do
      conn = post(conn, ~p"/api/send-instructions", %{email: user.email})

      assert json_response(conn, 200)["message"] =~ "you will receive"
    end

    test "silently fail for unregistered email", %{conn: conn} do
      conn = post(conn, ~p"/api/send-instructions", %{email: @unknown_user_email})

      assert json_response(conn, 200)["message"] =~ "you will receive"
    end
  end
end
