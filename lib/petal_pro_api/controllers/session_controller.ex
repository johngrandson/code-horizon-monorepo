defmodule PetalProApi.SessionController do
  use PetalProWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias PetalPro.Accounts
  alias PetalPro.Accounts.User
  alias PetalProApi.Schemas

  action_fallback PetalProWeb.FallbackController

  tags ["session"]

  operation :create,
    summary: "Authenticate user",
    description: "Authenticate user and generate bearer token",
    request_body: {"User credentials", "application/json", Schemas.UserCredentials},
    responses: [
      ok: {"Authenticated response", "application/json", Schemas.AuthResponse},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def create(_conn, %{"email" => nil}) do
    {:error, :unauthorized}
  end

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %User{} = user ->
        token = Accounts.create_user_api_token(user)

        render(conn, :create, token: token, token_type: "bearer")

      nil ->
        {:error, :unauthorized}
    end
  end
end
