defmodule PetalProWeb.BlogMakerRoutes do
  @moduledoc """
  Routes for Blog module.
  Defines both admin/management routes and public display routes.
  """
  defmacro __using__(_) do
    quote do
      # Admin/Management routes - require authentication and module access
      scope "/app", PetalProWeb do
        pipe_through [:browser, :authenticated, :subscribed_entity]

        # Organization-scoped routes
        scope "/org/:org_slug" do
          live_session :blog_org_authenticated,
            on_mount: [
              {PetalProWeb.UserOnMountHooks, :require_authenticated_user},
              {PetalProWeb.OrgOnMountHooks, :assign_org_data},
              {PetalProWeb.SubscriptionPlugs, :subscribed_org},
              {PetalProWeb.AppModuleOnMountHooks, {:require_module, "blog_maker"}}
            ] do
            live "/blog-maker", BlogMakerLive.Index, :index
            live "/blog-maker/new", BlogMakerLive.Index, :new
            live "/blog-maker/:id/edit", BlogMakerLive.Index, :edit

            live "/blog-maker/:id", BlogMakerLive.Show, :show
            live "/blog-maker/:id/show/edit", BlogMakerLive.Show, :edit
            live "/blog-maker/:id/show/edit/files/:image_target", BlogMakerLive.Show, :files
            live "/blog-maker/:id/show/publish", BlogMakerLive.Show, :publish
          end
        end
      end

      # Public display routes - no authentication required
      scope "/", PetalProWeb do
        pipe_through [:browser, :public_layout]

        live_session :blog_assigns_org_data,
          on_mount: [
            {PetalProWeb.OrgOnMountHooks, :assign_public_org_data}
          ] do
          live "/blog-maker/:org_slug/", BlogMakerLive.PublicIndex, :index
          live "/blog-maker/:org_slug/:post_slug", BlogMakerLive.PublicShow, :show
        end
      end
    end
  end
end
