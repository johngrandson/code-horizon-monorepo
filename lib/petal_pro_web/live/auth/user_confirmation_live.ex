defmodule PetalProWeb.UserConfirmationLive do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.Accounts

  def mount(params, _session, socket) do
    {:ok, assign(socket, token: params["token"]), temporary_assigns: [token: nil]}
  end

  def render(assigns) do
    ~H"""
    <.auth_layout title={gettext("Confirm account")}>
      <:logo>
        <.logo_icon class="w-20 h-20" />
      </:logo>

      <.p class="text-center">
        {gettext("Touch the button below to confirm your account.")}
      </.p>

      <.form
        :let={f}
        id="confirmation_form"
        class="mt-5"
        phx-submit="confirm_account"
        as={:user}
        for={%{}}
        action={~p"/auth/confirm/#{@token}"}
      >
        <.hidden_input form={f} field={:token} value={@token} />
        <.button
          class="w-full"
          phx-disable-with={gettext("Confirming...")}
          label={gettext("Confirm my account")}
        />
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
    </.auth_layout>
    """
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, user} ->
        Accounts.user_lifecycle_action("after_confirm_email", user)

        {:noreply,
         socket
         |> put_flash(:info, gettext("User confirmed successfully."))
         |> redirect(to: ~p"/auth/sign-in")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: PetalProWeb.Helpers.home_path(socket.assigns.current_user))}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, gettext("User confirmation link is invalid or it has expired."))
             |> redirect(to: ~p"/")}
        end
    end
  end
end
