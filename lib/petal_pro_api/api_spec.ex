defmodule PetalProApi.ApiSpec do
  @moduledoc false

  @behaviour OpenApiSpex.OpenApi

  alias OpenApiSpex.Components
  alias OpenApiSpex.Info
  alias OpenApiSpex.MediaType
  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Paths
  alias OpenApiSpex.Response
  alias OpenApiSpex.Schema
  alias OpenApiSpex.SecurityScheme
  alias OpenApiSpex.Server
  alias PetalProWeb.Endpoint
  alias PetalProWeb.Router

  @impl OpenApi
  @spec spec :: OpenApiSpex.OpenApi.t()
  def spec do
    open_api = %OpenApi{
      servers: [
        # Populate the Server info from a phoenix endpoint
        Server.from_endpoint(Endpoint)
      ],
      info: %Info{
        title: "Petal Pro API",
        version: "1.0"
      },
      components: %Components{
        securitySchemes: %{"authorization" => %SecurityScheme{type: "http", scheme: "bearer"}},
        responses: %{
          unauthorised: unauthorised_response(),
          forbidden: forbidden_response(),
          unprocessable_entity: unprocessable_entity_response(),
          no_content: no_content_response()
        }
      },
      # Populate the paths from a phoenix router
      paths: Paths.from_router(Router)
    }

    # Discover request/response schemas from path specs
    OpenApiSpex.resolve_schema_modules(open_api)
  end

  defp unauthorised_response do
    %Response{
      description: "Unauthorised",
      content: %{
        "application/json" => %MediaType{
          schema: %Schema{type: :object},
          example: %{errors: %{details: "Unauthorised"}}
        }
      }
    }
  end

  defp forbidden_response do
    %Response{
      description: "Forbidden",
      content: %{
        "application/json" => %MediaType{
          schema: %Schema{type: :object},
          example: %{errors: %{details: "Forbidden"}}
        }
      }
    }
  end

  defp unprocessable_entity_response do
    %Response{
      description: "Unprocessable Entity",
      content: %{
        "application/json" => %MediaType{
          schema: %Schema{type: :object},
          example: %{errors: %{details: "Unprocessable Entity"}}
        }
      }
    }
  end

  defp no_content_response do
    %Response{description: "No Content"}
  end
end
