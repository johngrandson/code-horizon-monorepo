defmodule PetalProWeb.AuthRoutes do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      scope "/auth", PetalProWeb do
        pipe_through [:browser]

        delete "/sign-out", UserSessionController, :delete

        live_session :current_user,
          on_mount: [{PetalProWeb.UserOnMountHooks, :maybe_assign_user}] do
          live "/confirm/:token", UserConfirmationLive, :edit
          live "/confirm", UserConfirmationInstructionsLive, :new
          live "/reset-password/:token", UserResetPasswordLive, :edit
        end
      end

      scope "/auth", PetalProWeb do
        pipe_through [:browser, :redirect_if_user_is_authenticated]

        live_session :redirect_if_user_is_authenticated,
          on_mount: [{PetalProWeb.UserOnMountHooks, :redirect_if_user_is_authenticated}] do
          live "/register", UserRegistrationLive, :new
          live "/sign-in", UserSignInLive, :new
          live "/sign-in/passwordless", PasswordlessAuthLive, :sign_in

          live "/sign-in/passwordless/enter-pin/:hashed_user_id",
               PasswordlessAuthLive,
               :sign_in_code

          live "/reset-password", UserForgotPasswordLive, :new
        end

        post "/sign-in", UserSessionController, :create
        post "/sign-in/passwordless", UserSessionController, :create_from_token

        get "/:provider", UserUeberauthController, :request
        get "/:provider/callback", UserUeberauthController, :callback
      end
    end
  end
end
