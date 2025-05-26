defmodule PetalProWeb.AdminRoutes do
  @moduledoc false
  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router

  defmacro __using__(_) do
    quote do
      scope "/admin", PetalProWeb do
        pipe_through [:browser, :authenticated, :require_admin_user]

        live_dashboard "/server",
          metrics: PetalProWeb.Telemetry,
          ecto_repos: [PetalPro.Repo],
          ecto_psql_extras_options: [long_running_queries: [threshold: "200 milliseconds"]]

        oban_dashboard("/oban")

        live_session :require_admin_user,
          on_mount: [
            {PetalProWeb.UserOnMountHooks, :require_admin_user}
          ] do
          live "/dashboard", AdminDashboardLive, :index
          live "/users", AdminUserLive.Index, :index
          live "/users/new", AdminUserLive.Index, :new
          live "/users/:user_id/edit", AdminUserLive.Index, :edit
          live "/users/:user_id", AdminUserLive.Show, :show
          live "/users/:user_id/show/edit", AdminUserLive.Show, :edit

          live "/orgs", AdminOrgLive.Index, :index
          live "/orgs/new", AdminOrgLive.Index, :new
          live "/orgs/:slug/edit", AdminOrgLive.Index, :edit
          live "/orgs/:slug", AdminOrgLive.Show, :show
          live "/orgs/:slug/show/edit", AdminOrgLive.Show, :edit

          live "/logs", LogsLive, :index
          live "/ai-chat", AdminAiChatLive
          live "/subscriptions", AdminSubscriptionsLive

          live "/posts", AdminPostLive.Index, :index
          live "/posts/new", AdminPostLive.Index, :new
          live "/posts/:id/edit", AdminPostLive.Index, :edit

          live "/posts/:id", AdminPostLive.Show, :show
          live "/posts/:id/show/edit", AdminPostLive.Show, :edit
          live "/posts/:id/show/edit/files/:image_target", AdminPostLive.Show, :files
          live "/posts/:id/show/publish", AdminPostLive.Show, :publish

          live "/settings", AdminSettingLive.Index, :index
          live "/settings/new", AdminSettingLive.Index, :new
          live "/settings/:id/edit", AdminSettingLive.Index, :edit

          live "/settings/:id", AdminSettingLive.Show, :show
          live "/settings/:id/show/edit", AdminSettingLive.Show, :edit

          live "/app-modules", AdminAppModuleLive.Index, :index
          live "/app-modules/new", AdminAppModuleLive.Index, :new
          live "/app-modules/:id/edit", AdminAppModuleLive.Index, :edit

          live "/app-modules/:id", AdminAppModuleLive.Show, :show
          live "/app-modules/:id/show/edit", AdminAppModuleLive.Show, :edit
        end
      end
    end
  end
end
