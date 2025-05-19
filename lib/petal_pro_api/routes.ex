defmodule PetalProApi.Routes do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      pipeline :api do
        plug :accepts, ["json"]
        plug OpenApiSpex.Plug.PutApiSpec, module: PetalProApi.ApiSpec
      end

      pipeline :api_authenticated do
        plug :fetch_api_user
      end

      scope "/api", PetalProApi do
        pipe_through :api

        post "/sign-in", SessionController, :create
        post "/register", RegistrationController, :register
        post "/send-instructions", RegistrationController, :send_instructions
      end

      scope "/api" do
        pipe_through :api

        get "/openapi", OpenApiSpex.Plug.RenderSpec, []
      end

      scope "/api", PetalProApi do
        pipe_through [:api, :api_authenticated]

        get "/user/:id", ProfileController, :show
        patch "/user/:id/update", ProfileController, :update_profile
        post "/user/:id/request-new-email", ProfileController, :request_new_email
        post "/user/:id/change-password", ProfileController, :change_password
      end
    end
  end
end
