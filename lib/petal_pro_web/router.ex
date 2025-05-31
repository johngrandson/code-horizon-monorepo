defmodule PetalProWeb.Router do
  use PetalProWeb, :router

  import PetalProWeb.OrgPlugs
  import PetalProWeb.SubscriptionPlugs
  import PetalProWeb.UserAuth

  alias PetalProWeb.OnboardingPlug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PetalProWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        ContentSecurityPolicy.serialize(struct(ContentSecurityPolicy.Policy, PetalPro.config(:content_security_policy)))
    }

    plug :fetch_current_user
    plug :fetch_impersonator_user
    plug :kick_user_if_suspended_or_deleted
    plug PetalProWeb.PutUserSocketTokenPlug
    plug PetalProWeb.SetLocalePlug, gettext: PetalProWeb.Gettext
  end

  pipeline :public_layout do
    plug :put_layout, html: {PetalProWeb.Layouts, :public}
  end

  pipeline :authenticated do
    plug PetalProWeb.PutSessionRequestPathPlug
    plug :require_authenticated_user
    plug OnboardingPlug
    plug :assign_org_data
  end

  pipeline :subscribed_entity do
    plug :subscribed_entity_only
  end

  pipeline :subscribed_org do
    plug :subscribed_org_only
  end

  pipeline :subscribed_user do
    plug :subscribed_user_only
  end

  # Public routes
  scope "/", PetalProWeb do
    pipe_through [:browser, :public_layout]

    # Add public controller routes here
    get "/", PageController, :landing_page
    get "/privacy", PageController, :privacy
    get "/license", PageController, :license

    live_session :public, layout: {PetalProWeb.Layouts, :public} do
      # Add public live routes here
      live "/blog", BlogLive.Index, :index
      live "/blog/:slug", BlogLive.Show, :show
    end
  end

  # App routes - for signed in and confirmed users only
  scope "/app", PetalProWeb do
    pipe_through [:browser, :authenticated]

    # Add controller authenticated routes here
    put "/users/settings/update-password", UserSettingsController, :update_password
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
    get "/users/totp", UserTOTPController, :new
    post "/users/totp", UserTOTPController, :create

    live_session :authenticated,
      on_mount: [
        {PetalProWeb.UserOnMountHooks, :attach_read_relevant_notifications_hook},
        {PetalProWeb.UserOnMountHooks, :require_authenticated_user},
        {PetalProWeb.OrgOnMountHooks, :assign_org_data},
        {PetalProWeb.UserOnMountHooks, :assign_current_org},
        {PetalProWeb.SubscriptionPlugs, :subscribed_entity}
      ] do
      # Add live authenticated routes here

      use PetalProWeb.BillingRoutes

      live "/", DashboardLive
      live "/users/onboarding", UserOnboardingLive
      live "/users/edit-profile", EditProfileLive
      live "/users/edit-email", EditEmailLive
      live "/users/change-password", EditPasswordLive
      live "/users/edit-notifications", EditNotificationsLive
      live "/users/org-invitations", UserOrgInvitationsLive
      live "/users/two-factor-authentication", EditTotpLive

      live "/ai-chat", UserAiChatLive

      live "/orgs", OrgsLive.Index, :index
      live "/orgs/new", OrgsLive.Index, :new

      scope "/org/:org_slug" do
        live "/", OrgDashboardLive
        live "/edit", EditOrgLive
        live "/team", OrgTeamLive, :index
        live "/team/invite", OrgTeamLive, :invite
        live "/team/memberships/:id/edit", OrgTeamLive, :edit_membership
      end
    end
  end

  if PetalPro.config(:impersonation_enabled?) do
    use PetalProWeb.AuthImpersonationRoutes
  end

  scope "/" do
    use PetalProWeb.AuthRoutes
    use PetalProWeb.SubscriptionRoutes
    use PetalProWeb.MailblusterRoutes
    use PetalProWeb.AdminRoutes
    use PetalProApi.Routes

    # App Modules routes
    use PetalProWeb.VirtualQueuesRoutes

    # DevRoutes must always be last
    use PetalProWeb.DevRoutes
  end
end
