defmodule PetalProApi.ProfileController do
  use PetalProWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias PetalPro.Accounts
  alias PetalPro.Accounts.Permissions
  alias PetalProApi.Schemas

  action_fallback PetalProWeb.FallbackController

  plug :match_current_user

  tags ["profile"]

  security [%{"authorization" => []}]

  operation :show,
    summary: "Show profile",
    description: "Show profile for user",
    parameters: [
      id: [in: :path, name: "id", type: :integer]
    ],
    responses: [
      ok: {"User", "application/json", Schemas.User},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"},
      forbidden: %Reference{"$ref": "#/components/responses/forbidden"}
    ]

  def show(conn, _params) do
    user = conn.assigns.user

    render(conn, :show, user: user)
  end

  operation :update_profile,
    summary: "Update profile",
    description: "Update profile for user",
    parameters: [
      id: [in: :path, name: "id", type: :integer]
    ],
    request_body: {"Update profile attributes", "application/json", Schemas.UpdateProfile, required: true},
    responses: [
      ok: {"Updated User", "application/json", Schemas.User},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"},
      forbidden: %Reference{"$ref": "#/components/responses/forbidden"},
      unprocessable_entity: %Reference{"$ref": "#/components/responses/unprocessable_entity"}
    ]

  def update_profile(conn, user_params) do
    user = conn.assigns.user

    case Accounts.update_profile(user, user_params) do
      {:ok, applied_user} ->
        Accounts.user_lifecycle_action("after_update_profile", applied_user)

        render(conn, :show, user: applied_user)

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{user: gettext("Update failed. Please check the form for issues")}})
    end
  end

  operation :request_new_email,
    summary: "Request new email",
    description: "Request new email address for user",
    parameters: [
      id: [in: :path, name: "id", type: :integer]
    ],
    request_body: {"New email attributes", "application/json", Schemas.NewEmail, required: true},
    responses: [
      ok: {"Success", "application/json", Schemas.MessageResponse},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"},
      forbidden: %Reference{"$ref": "#/components/responses/forbidden"},
      unprocessable_entity: %Reference{"$ref": "#/components/responses/unprocessable_entity"}
    ]

  def request_new_email(conn, %{"requested_email" => _requested_email} = user_params) do
    user = conn.assigns.user

    with {:ok, applied_user} <-
           Accounts.check_if_can_change_user_email(user, user_params) do
      Accounts.deliver_user_update_email_instructions(
        applied_user,
        user.email,
        &url(~p"/app/users/settings/confirm-email/#{&1}")
      )

      Accounts.user_lifecycle_action("request_new_email", user, %{new_email: user_params["email"]})

      json(conn, %{
        message: gettext("A link to confirm your e-mail change has been sent to the new address.")
      })
    end
  end

  operation :change_password,
    summary: "Change password",
    description: "Change current user's password",
    parameters: [
      id: [in: :path, name: "id", type: :integer]
    ],
    request_body: {"Change password attributes", "application/json", Schemas.ChangePassword, required: true},
    responses: [
      ok: {"Success", "application/json", Schemas.MessageResponse},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"},
      forbidden: %Reference{"$ref": "#/components/responses/forbidden"},
      unprocessable_entity: %Reference{"$ref": "#/components/responses/unprocessable_entity"}
    ]

  def change_password(conn, %{"current_password" => password} = user_params) do
    user = conn.assigns.user

    with {:ok, _user} <- Accounts.update_user_password(user, password, user_params) do
      json(conn, %{message: gettext("Password updated successfully.")})
    end
  end

  def match_current_user(conn, _params) do
    user_id = String.to_integer(conn.params["id"])
    user = Accounts.get_user!(user_id)

    current_user = conn.assigns.current_user

    if current_user.id == user_id || Permissions.can_access_user_profiles?(current_user) do
      assign(conn, :user, user)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(html: PetalProWeb.ErrorHTML, json: PetalProWeb.ErrorJSON)
      |> render(:"403")
      |> halt()
    end
  end
end
