## Petal Pro API

You can use the Petal Pro API for user management (register, sign in and update). It comes with OpenAPI support out of the box.

### Using the Swagger UI

You can see OpenAPI in action if you navigate to the Swagger interface:

```
http://localhost:4000/dev/swaggerui
```

To make an API call:

1. Expand a route (e.g. `/api/register`)
2. Click the "Try it out" button
3. Fill out the appropriate parameter/request fields
4. Click "Execute"
5. Check the Server Response for output

Some routes are protected - calling these routes without an authenticated user will result in an `:unauthorized` response.

To authenticate a user:

1. Follow the steps (above) to execute the `/api/sign-in` API call (you'll be asked to provide an `email` and a `password`)
2. In the response body, copy the value of the `token` property
3. Go to the top of the page and click the "Authorize" button
4. Paste the bearer token into the "Value" input and click "Authorize" again

While the bearer token is valid, protected routes will provide a response other than `:unauthorized`. By default, the bearer token will be valid for the period of thirty days

### Generating the Open API Spec

You can generate an `openapi.json` file with the following mix command:

```shell
mix openapi.spec.json --spec PetalProApi.ApiSpec
```

Alternatively, if you navigate to the [Swagger UI](http://localhost:4000/dev/swaggerui), you can click the link under the "Petal Pro API" heading. The contents of the `.json` file will be displayed in the browser. Use the browsers "Save As..." feature to save the file to local storage.

## Extending the API

Say you want to add an API call that returns a list of Organisations for a user. The following is an example of how this might be achieved

### Create the API Code

First, create the API controller `lib/petal_pro_api/controllers/membership_controller.ex`:

```elixir
defmodule PetalProApi.MembershipController do
  use PetalProWeb, :controller
  alias PetalPro.Accounts
  alias PetalPro.Orgs

  action_fallback PetalProWeb.FallbackController

  def list(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with orgs <- Orgs.list_orgs(user) do
      org_names = Enum.map(orgs, fn x -> x.name end)

      json(conn, org_names)
    end
  end
end
```

Then create the related unit test `/test/petal_pro_api/membership_controller_test.exs`:

```elixir
defmodule PetalProApi.MembershipControllerTest do
  use PetalProWeb.ConnCase

  setup %{conn: conn} do
    user = PetalPro.AccountsFixtures.confirmed_user_fixture()
    org = PetalPro.OrgsFixtures.org_fixture(user)
    membership = PetalPro.Orgs.get_membership!(user, org.slug)

    {:ok,
     conn: put_req_header(conn, "accept", "application/json"),
     user: user,
     org: org,
     membership: membership}
  end

  describe "list" do
    test "list organizations", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/user/#{user.id}/orgs")

      assert orgs = json_response(conn, 200)
      assert Enum.count(orgs) > 0
    end
  end
end
```

Finally, for the test to work, you need to add the following line to `/lib/petal_pro_api/routes.ex`:

```elixir
  # Scope statement at line 27:
  scope "/api", PetalProApi do
    pipe_through [:api, :api_authenticated]

    get "/user/:id", ProfileController, :show
    patch "/user/:id/update", ProfileController, :update_profile
    post "/user/:id/request-new-email", ProfileController, :request_new_email
    post "/user/:id/change-password", ProfileController, :change_password

    # Add this line...
    get "/user/:id/orgs", MembershipController, :list
  end
```

But if you run the test...

```shell
mix test test/petal_pro_api/membership_controller_test.exs
```

...it won't pass:

```shell
Compiling 2 files (.ex)
Excluding tags: [:petal_framework]



  1) test list list organizations (PetalProApi.MembershipControllerTest)
     test/petal_pro_api/membership_controller_test.exs:17
     ** (RuntimeError) expected response with status 200, got: 401, with body:
     "{\"errors\":{\"details\":\"unauthenticated\"}}"
     code: assert orgs = json_response(conn, 200)
     stacktrace:
       (phoenix 1.7.6) lib/phoenix/test/conn_test.ex:373: Phoenix.ConnTest.response/2
       (phoenix 1.7.6) lib/phoenix/test/conn_test.ex:419: Phoenix.ConnTest.json_response/2
       test/petal_pro_api/membership_controller_test.exs:20: (test)


Finished in 0.1 seconds (0.00s async, 0.1s sync)
1 test, 1 failure
```

That's because the route has been placed it in a `scope` that pipes through `:api_authenticated`:

```elixir
scope "/api", PetalProApi do
  pipe_through [:api, :api_authenticated]

  ...

  get "/user/:id/orgs", MembershipController, :list
end
```

### Adjusting for Authentication

Adding `put_bearer_token` to the "list organizations" test in `membership_controllers_test.exs` will address the issue:

```elixir
test "list organizations", %{conn: conn, user: user} do
  conn =
    conn
    |> put_bearer_token(user)
    |> get(~p"/api/user/#{user.id}/orgs")

  assert orgs = json_response(conn, 200)
  assert Enum.count(orgs) > 0
end
```

`put_bearer_token` is a helper function that can be found in `/test/support/conn_case.ex`. It will generate a bearer token for `user` and inject an `authorization` header into the `conn` object. The `:api_authenticated` pipeline will use this header to check validity of the bearer token.

If you run the test again, this time the user will be authenticated and it will pass!

```shell
user@host petal_pro % mix test test/petal_pro_api/membership_controller_test.exs
Excluding tags: [:petal_framework]

.
Finished in 0.2 seconds (0.00s async, 0.2s sync)
1 test, 0 failures
```

However, now is a good time to think about access control (authorisation). Let's assume users should only retrieve Organisations for themselves (but admin users can retrieve Organisations for any user). Copying the code that's in `profile_controller.ex`, you can add the `match_current_user` plug to `membership_controller.ex`:

```elixir
defmodule PetalProApi.MembershipController do
  use PetalProWeb, :controller
  alias PetalPro.Accounts
  alias PetalPro.Orgs

  action_fallback PetalProWeb.FallbackController

  plug :match_current_user

  def list(conn, _params) do
    user = conn.assigns.user

    with orgs <- Orgs.list_orgs(user) do
      org_names = Enum.map(orgs, fn x -> x.name end)

      json(conn, org_names)
    end
  end

  def match_current_user(conn, _params) do
    user_id = String.to_integer(conn.params["id"])
    user = Accounts.get_user!(user_id)

    current_user = conn.assigns.current_user

    if current_user.role == :admin || current_user.id == user_id do
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
```

> Note that the `list` function has changed - it assumes the `user` assign has been set

The `match_current_user` plug checks the current authenticated user. If the user requested _is_ the current user or the current user is an admin, then the `user` assigns is set. Otherwise HTTP error `403` (`:forbidden`) is returned (preventing further execution).

To double check that your code is working properly, add two tests to `membership_controller_test.exs`:

```elixir
defmodule PetalProApi.MembershipControllerTest do
  use PetalProWeb.ConnCase

  setup %{conn: conn} do
    user = PetalPro.AccountsFixtures.confirmed_user_fixture()
    other_user = PetalPro.AccountsFixtures.user_fixture()
    admin_user = PetalPro.AccountsFixtures.admin_fixture()
    org = PetalPro.OrgsFixtures.org_fixture(user)
    membership = PetalPro.Orgs.get_membership!(user, org.slug)

    {:ok,
     conn: put_req_header(conn, "accept", "application/json"),
     user: user,
     other_user: other_user,
     admin_user: admin_user,
     org: org,
     membership: membership}
  end

  describe "list" do
    ...

    # Two new tests...
    test "can't list organizations for other user", %{
      conn: conn,
      user: user,
      other_user: other_user
    } do
      conn =
        conn
        |> put_bearer_token(user)
        |> get(~p"/api/user/#{other_user.id}/orgs")

      assert json_response(conn, 403)
    end

    test "admin can list organizations for other user", %{
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
end
```

> Note that `other_user` and `admin_user` have been added to the `setup` function

If you run `mix test` again, then all three unit tests should pass:

```shell
user@host petal_pro % mix test test/petal_pro_api/membership_controller_test.exs
Excluding tags: [:petal_framework]

...
Finished in 0.3 seconds (0.00s async, 0.3s sync)
3 tests, 0 failures
```

### OpenAPI Specification

Great! Your new API call is fully operational. However, it won't be added to the Open API spec automatically. To do this, you add meta data to the API function using `OpenApiSpex`.

In `membership_controller.ex` add the following:

```elixir
defmodule PetalProApi.MembershipController do
  use PetalProWeb, :controller

  # Add these lines
  use OpenApiSpex.ControllerSpecs
  alias OpenApiSpex.Reference
  alias PetalProApi.Schemas

  ...

  plug :match_current_user

  # Add these lines too
  tags ["membership"]
  security [%{"authorization" => []}]

  ...

end
```

The `tags` call is used to group API calls together in your Open API definition. In the SwaggerUI page, this will be used as a group heading.

The `security` call let's Open API know that all API calls in this file are protected by authentication. In the Swagger UI, routes that have been marked with the `security` function will be displayed with a padlock.

> NB - The "authorization" string is a reference to a `securitySchemes` setting that's in `/lib/petal_pro_api/api_spec.ex`. Open API supports multiple authentication schemes. But for the purposes of this example, "authorization" refers to the bearer/header token mechanism that has been setup with phx.gen.auth.

Next, you need to define an Open API Operation for the `:list` function call in `membership_controller.ex`:

```elixir
operation :list,
  summary: "List organizations",
  description: "List organizations for user",
  parameters: [
    id: [in: :path, name: "id", type: :integer]
  ],
  responses: [
    ok: {"Organisations", "application/json", Schemas.OrganisationNames},
    unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"},
    forbidden: %Reference{"$ref": "#/components/responses/forbidden"}
  ]

def list(conn, _params) do
  ...
end
```

There's a lot going on here! Let's step through the various parts of the `operation`:

* `:list` refers to the `list` method (underneath)
* `summary` and `description` are a short and long descriptions (respectively)
* `parameters` defines any variable that may be defined in the url
* `responses` is the list of possible outcomes after the function has been called

An `operation` defines the list of expected inputs and outputs. Which is great for generating code/documentation (e.g. for the Swagger UI). In particular, there are three possible outcomes in the above definition:

* `:ok` - when the call is successful, then the output will be a list of Organisation names. This is defined by the `OrganisationNames` schema. There's more on the schema (below)
* `:unauthorized` - a common response that's defined in the `api_spec.ex` file
* `:forbidden` - also defined in `api_spec.ex`

To round out the Open API definition, we need to add the following Schema to `/lib/petal_pro_api/schemas.ex`:

```elixir
defmodule OrganisationNames do
  OpenApiSpex.schema(%{
    title: "OrganisationNames",
    description: "List of organization names for a user",
    type: :array,
    items: %Schema{description: "name", type: :string},
    example: ["Mayfield Columbus", "Tracking Bronze"]
  })
end
```

This defines an array of type "string". The purpose of the schema is to define the output of a valid response - users can discover the format of the response via the Swagger UI.

### Accessing the API

The new API call should now be available! To view the Swagger UI, run the Phoenix server:

```shell
mix phx.server
```

Then navigate to the Swagger interface:

```
http://localhost:4000/dev/swaggerui
```

See the "Using the Swagger UI" section (at the top of this README) to learn more about making API calls
