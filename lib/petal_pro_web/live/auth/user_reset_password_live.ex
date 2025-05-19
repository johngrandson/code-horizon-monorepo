defmodule PetalProWeb.UserResetPasswordLive do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.Accounts

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    socket =
      case socket.assigns do
        %{user: user} ->
          assign(socket, :form, to_form(Accounts.change_user_password(user)))

        _ ->
          socket
      end

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def render(assigns) do
    ~H"""
    <.auth_layout title={gettext("Reset password")}>
      <:logo>
        <.logo_icon class="w-20 h-20" />
      </:logo>

      <div>
        <.form for={@form} id="reset_password_form" phx-submit="reset_password" phx-change="validate">
          <.error :if={@form.source.action == :insert}>
            {gettext("Oops, something went wrong! Please check the errors below.")}
          </.error>

          <.field
            type="password"
            field={@form[:password]}
            label={gettext("New password")}
            value={@form[:password].value}
            autocomplete="new-password"
            phx-debounce="blur"
            required
          />
          <.field
            type="password"
            field={@form[:password_confirmation]}
            label={gettext("Confirm new password")}
            value={@form[:password_confirmation].value}
            autocomplete="new-password"
            phx-debounce="blur"
            required
          />

          <div class="flex justify-end mt-6">
            <.button label={gettext("Reset password")} phx-disable-with={gettext("Resetting...")} />
          </div>
        </.form>
      </div>

      <:bottom_links>
        <div class="flex justify-center gap-3">
          <.link class="text-sm underline" href={~p"/auth/register"}>
            {gettext("Register")}
          </.link>
          <.link class="text-sm underline" href={~p"/auth/sign-in"}>
            {gettext("Sign in")}
          </.link>
        </div>
      </:bottom_links>
    </.auth_layout>
    """
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/auth/sign-in")}

      {:error, changeset} ->
        changeset = Map.put(changeset, :action, :insert)
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, gettext("Reset password link is invalid or it has expired."))
      |> redirect(to: ~p"/")
    end
  end
end
