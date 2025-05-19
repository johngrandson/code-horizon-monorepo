defmodule PetalProWeb.UserImpersonationController do
  use PetalProWeb, :controller

  alias PetalPro.Accounts
  alias PetalPro.Accounts.Permissions
  alias PetalProWeb.Helpers
  alias PetalProWeb.UserAuth

  def create(conn, %{"id" => id}) do
    impersonator_user = conn.assigns[:current_user]

    user = Accounts.get_user!(id)

    if Permissions.can_impersonate?(user, impersonator_user) do
      conn
      |> put_flash(:info, gettext("Impersonating %{name}", name: Helpers.user_name(user)))
      |> impersonate_user(impersonator_user, user)
    else
      conn
      |> put_flash(:error, gettext("Invalid user or not permitted"))
      |> redirect(to: ~p"/")
    end
  end

  def delete(conn, _params) do
    if get_session(conn, :impersonator_user_id) do
      impersonator_user = Accounts.get_user!(get_session(conn, :impersonator_user_id))

      conn =
        conn
        |> delete_session(:impersonator_user_id)
        |> UserAuth.put_user_into_session(impersonator_user)

      Accounts.user_lifecycle_action("after_restore_impersonator", impersonator_user, %{
        ip: UserAuth.get_ip(conn),
        target_user_id: conn.assigns.current_user.id
      })

      # No need for MFA - `impersonator_user` was already logged in
      conn
      |> put_flash(
        :info,
        gettext("You're back as %{name}", name: Helpers.user_name(impersonator_user))
      )
      |> redirect(to: ~p"/admin/users")
    else
      redirect(conn, to: ~p"/")
    end
  end

  def impersonate_user(conn, impersonator_user, user) do
    conn =
      conn
      |> UserAuth.put_user_into_session(user)
      |> put_session(:impersonator_user_id, impersonator_user.id)

    Accounts.user_lifecycle_action("after_impersonate_user", impersonator_user, %{
      ip: UserAuth.get_ip(conn),
      target_user_id: user.id
    })

    # No need for MFA - `impersonator_user` was already logged in
    UserAuth.redirect_user_after_login_with_remember_me(conn, user)
  end
end
