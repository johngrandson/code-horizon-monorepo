defmodule PetalProApi.Schemas do
  @moduledoc false
  alias OpenApiSpex.Schema

  require OpenApiSpex

  defmodule UserCredentials do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "UserCredentials",
      description: "Request body for user credentials",
      type: :object,
      properties: %{
        email: %Schema{type: :string, description: "Email address", format: :email},
        password: %Schema{type: :string, description: "Password", format: :password}
      },
      required: [:name, :email],
      example: %{
        "email" => "admin@example.com",
        "password" => "password"
      }
    })
  end

  defmodule AuthResponse do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "AuthResponse",
      description: "Successful authentication response",
      type: :object,
      properties: %{
        token: %Schema{type: :string, description: "Token"},
        token_type: %Schema{type: :string, description: "Token Type"}
      },
      required: [:token, :token_type],
      example: %{
        token: "vW4sIvFvqkw6iogdhNyyFXa2nKg4LlsVobOTR721hbs",
        token_type: "bearer"
      }
    })
  end

  defmodule UserRegistration do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "UserRegistration",
      description: "Request body for user registration",
      type: :object,
      properties: %{
        name: %Schema{type: :string, description: "Name"},
        email: %Schema{type: :string, description: "Email address", format: :email},
        password: %Schema{type: :string, description: "Password", format: :password},
        avatar: %Schema{type: :string, description: "Avatar url"}
      },
      required: [:name, :email, :password],
      example: %{
        "name" => "John Smith",
        "email" => "admin@example.com",
        "password" => "neat_password",
        "avatar" => ""
      }
    })
  end

  defmodule User do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "User",
      description: "Response body for user",
      type: :object,
      properties: %{
        id: %Schema{type: :int, description: "Id"},
        name: %Schema{type: :string, description: "Name"},
        email: %Schema{type: :string, description: "Email address", format: :email},
        is_confirmed: %Schema{type: :bool, description: "Email address is confirmed"},
        is_admin: %Schema{type: :bool, description: "Is an admin user"},
        role: %Schema{type: :string, description: "Role"},
        avatar: %Schema{type: :string, description: "Avatar url"},
        is_suspended: %Schema{type: :bool, description: "User has been suspended"},
        is_deleted: %Schema{type: :bool, description: "Is deleted"},
        is_onboarded: %Schema{type: :bool, description: "Is onboarded"}
      },
      required: [:id, :name, :email],
      example: %{
        "id" => "1",
        "name" => "John Smith",
        "email" => "admin@example.com",
        "is_confirmed" => true,
        "is_admin" => true,
        "role" => "admin",
        "avatar" => "",
        "is_suspended" => false,
        "is_deleted" => false,
        "is_onboarded" => true
      }
    })
  end

  defmodule UpdateProfile do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "UpdateProfile",
      description: "Request body for user profile changes",
      type: :object,
      properties: %{
        name: %Schema{type: :string, description: "Name"},
        avatar: %Schema{type: :string, description: "Avatar url"}
      },
      example: %{
        "name" => "John Smith",
        "avatar" => "https://example.com/some/image.jpg"
      }
    })
  end

  defmodule NewEmail do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "NewEmail",
      description: "Body for request new email",
      type: :object,
      properties: %{
        requested_email: %Schema{
          type: :string,
          description: "Requested email address",
          format: :email
        }
      },
      require: {:requested_email},
      example: %{
        "requested_email" => "changed@example.com"
      }
    })
  end

  defmodule ExistingEmail do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "ExistingEmail",
      description: "Request body for send instructions",
      type: :object,
      properties: %{
        email: %Schema{
          type: :string,
          description: "Email address of existing user",
          format: :email
        }
      },
      require: {:email},
      example: %{
        "email" => "admin@example.com"
      }
    })
  end

  defmodule ChangePassword do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "ChangePassword",
      description: "Request body to change a user's password",
      type: :object,
      properties: %{
        current_password: %Schema{
          type: :string,
          description: "Current password",
          format: :password
        },
        password: %Schema{type: :string, description: "New password", format: :password},
        password_confirmation: %Schema{
          type: :string,
          description: "Confirm new password",
          format: :password
        }
      },
      require: {:current_password, :password, :password_confirmation},
      example: %{
        "current_password" => "password",
        "password" => "awesome_password",
        "password_confirmation" => "awesome_password"
      }
    })
  end

  defmodule MessageResponse do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "MessageResponse",
      description: "Response with message",
      type: :object,
      properties: %{
        message: %Schema{type: :string, description: "Message"}
      },
      example: %{message: "Example message!"}
    })
  end
end
