defmodule PetalProWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PetalProWeb, :controller
      use PetalProWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts uploads images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: PetalProWeb,
        formats: [:html, :json],
        layouts: [html: PetalProWeb.Layouts]

      use Gettext, backend: PetalProWeb.Gettext

      import Phoenix.Component, only: [to_form: 2]
      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.Component, global_prefixes: ~w(x-)

      use Phoenix.View,
        root: "lib/petal_pro_web/templates",
        namespace: PetalProWeb

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component, global_prefixes: ~w(x-)

      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PetalProWeb.Layouts, :app},
        global_prefixes: ~w(x-)

      on_mount({PetalProWeb.UserOnMountHooks, :maybe_assign_user})
      on_mount(PetalProWeb.RestoreLocaleHook)
      on_mount(PetalProWeb.AllowEctoSandboxHook)
      on_mount({PetalProWeb.ViewSetupHook, :reset_page_title})

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent, global_prefixes: ~w(x-)

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component, global_prefixes: ~w(x-)

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      # Core UI components and translation
      use PetalComponents
      use PetalProComponents
      use PrelineComponents
      use Gettext, backend: PetalProWeb.Gettext

      import PetalProWeb.CoreComponents
      import PetalProWeb.Helpers
      import Phoenix.HTML

      alias Phoenix.LiveView.JS

      # Shortcut for generating JS commands

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: PetalProWeb.Gettext
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PetalProWeb.Endpoint,
        router: PetalProWeb.Router,
        statics: PetalProWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
