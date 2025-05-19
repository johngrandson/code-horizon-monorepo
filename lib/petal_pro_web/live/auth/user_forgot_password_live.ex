defmodule PetalProWeb.UserForgotPasswordLive do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :user))}
  end

  def render(assigns) do
    ~H"""
    <.auth_layout title={gettext("Forgot your password?")}>
      <:logo>
        <.logo_icon class="w-20 h-20" />
      </:logo>

      <.form id="reset_password_form" for={@form} phx-submit="send_email">
        <.field
          type="email"
          field={@form[:email]}
          required
          placeholder={gettext("eg. sarah@gmail.com")}
          autocomplete="email"
        />

        <.button
          label={gettext("Send instructions to reset password")}
          phx-disable-with={gettext("Sending...")}
          class="w-full"
        />
      </.form>

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

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/auth/reset-password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/auth/sign-in")}
  end
end
