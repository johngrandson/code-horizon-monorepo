defmodule PetalProWeb.UserConfirmationInstructionsLive do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :user))}
  end

  def render(assigns) do
    ~H"""
    <.auth_layout title={gettext("Please confirm your email")}>
      <:logo>
        <.logo_icon class="w-20 h-20" />
      </:logo>
      <.p>
        {gettext(
          "A confirmation email should be in your inbox. If you can't find it then try clicking the button below."
        )}
      </.p>

      <.form for={@form} id="resend_confirmation_form" phx-submit="send_instructions" class="mt-5">
        <%= if @current_user do %>
          <.field type="hidden" field={@form[:email]} value={@current_user.email} />
        <% else %>
          <.field
            type="email"
            field={@form[:email]}
            label={gettext("Email")}
            placeholder={gettext("eg. john@gmail.com")}
          />
        <% end %>

        <.button class="w-full">{gettext("Resend confirmation instructions")}</.button>
      </.form>

      <:bottom_links>
        <%= if @current_user do %>
          <div class="flex justify-center gap-3">
            <.link class="text-sm underline" href={~p"/auth/sign-out"} method="delete">
              {gettext("Sign out")}
            </.link>
          </div>
        <% else %>
          <div class="flex justify-center gap-3">
            <.link class="text-sm underline" href={~p"/auth/register"}>
              {gettext("Register")}
            </.link>
            <.link class="text-sm underline" href={~p"/auth/sign-in"}>
              {gettext("Sign in")}
            </.link>
          </div>
        <% end %>
      </:bottom_links>

      <%= if PetalPro.config(:env) == :dev do %>
        <div class="fixed mt-10 left-10 bottom-10">
          <.alert color="warning">
            DEV ONLY: <.link href="/dev/mailbox" class="underline">Go to mailbox</.link>
          </.alert>
        </div>
      <% end %>
    </.auth_layout>
    """
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/auth/confirm/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
