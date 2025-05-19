defmodule PetalProApi.RegistrationController do
  use PetalProWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias PetalPro.Accounts
  alias PetalProApi.Schemas

  action_fallback PetalProWeb.FallbackController

  tags ["registration"]

  operation :register,
    summary: "Register user",
    description: "Register user",
    request_body: {"User registration attributes", "application/json", Schemas.UserRegistration, required: true},
    responses: [
      ok: {"Registered user", "application/json", Schemas.User},
      unprocessable_entity: %Reference{"$ref": "#/components/responses/unprocessable_entity"}
    ]

  def register(conn, user_params) do
    with {:ok, user} <- Accounts.register_user(user_params) do
      Accounts.user_lifecycle_action("after_register", user, %{registration_type: "api"})

      case Accounts.deliver_user_confirmation_instructions(user, &url(~p"/auth/confirm/#{&1}")) do
        {:ok, _email} ->
          render(conn, :show, user: user)

        {:error, _} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{
            errors: %{
              email: "User has been registered but email delivery failed. Please contact support."
            }
          })
      end
    end
  end

  operation :send_instructions,
    summary: "Send instructions",
    description: "Send confirmation instructions via email",
    request_body: {"Existing email attributes", "application/json", Schemas.ExistingEmail, required: true},
    responses: [
      ok: {"Message", "application/json", Schemas.MessageResponse}
    ]

  def send_instructions(conn, %{"email" => email}) do
    message =
      gettext(
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
      )

    with user when user != nil <- Accounts.get_user_by_email(email),
         {:ok, _email} <-
           Accounts.deliver_user_confirmation_instructions(user, &url(~p"/auth/confirm/#{&1}")) do
      json(conn, %{message: message})
    else
      _ ->
        json(conn, %{message: message})
    end
  end
end
