defmodule PetalProWeb.PasswordlessAuthLive do
  @moduledoc """
  This module is used to handle the passwordless auth flow.
  A user enters their email and submits. If no user exists for the user, then one is created with a random password.
  A user will fill in their name at the onboarding screen.

  Process:
  1: User submits email.
  2: Find or create a user, set it as assigns.auth_user
  3: Push patch to /passwordless/sign-in-code/:hashed_user_id
  4: User enters code that was sent to their email.
  5: A form is submited that POSTs a token to UserSessionController.create_from_token/2
  6: User is logged in
  """
  use PetalProWeb, :live_view

  alias PetalPro.Accounts
  alias PetalPro.Accounts.User
  alias PetalPro.Accounts.UserPin
  alias PetalPro.Events.Modules.Notifications.UserMailer

  require Logger

  @allowed_attempts 3
  @hash_salt "passwordless"

  def mount(params, _session, socket) do
    socket =
      assign(socket,
        page_title: gettext("Sign in"),
        form: to_form(Accounts.change_user_passwordless_registration(%User{}, %{})),
        user_return_to: Map.get(params, "user_return_to", nil),
        error_message: nil,
        auth_user: nil,
        enable_resend?: nil,
        sign_in_token: nil,
        token_form: to_form(build_token_changeset(%{}), as: :auth),
        loading: false,
        trigger_submit: false
      )

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :sign_in, _params), do: assign(socket, error_message: nil)

  defp apply_action(socket, :sign_in_code, %{"hashed_user_id" => hashed_user_id}) do
    user_id = decode_user_id(hashed_user_id)

    if socket.assigns.auth_user do
      socket
    else
      # Re-assign page variables if this is remounted (eg. socket disconnected)
      # This can happen on mobile devices when user switches to mail app to copy/paste pin
      auth_user = Accounts.get_user!(user_id)

      if UserPin.valid_pin_exists?(auth_user) do
        assign(socket, auth_user: auth_user)
      else
        push_patch(socket,
          to: ~p"/auth/sign-in/passwordless"
        )
      end
    end
  end

  def handle_event("submit_email", %{"user" => %{"email" => email}}, socket) do
    send_pin(socket, email)
  end

  # When pin is less than 6 digits, ignore it
  def handle_event("validate_pin", %{"auth" => %{"pin" => pin}}, socket) when byte_size(pin) < 6 do
    {:noreply, assign(socket, error_message: nil)}
  end

  # Handle nil user
  def handle_event("validate_pin", %{"auth" => %{"pin" => _pin}}, socket) when socket.assigns.auth_user == nil do
    {:noreply, push_patch(socket, to: ~p"/auth/sign-in/passwordless")}
  end

  def handle_event("validate_pin", %{"auth" => %{"pin" => submitted_pin}}, socket) when byte_size(submitted_pin) >= 6 do
    submitted_pin = String.trim(submitted_pin)

    pin_result = UserPin.validate_pin(socket.assigns.auth_user, submitted_pin, @allowed_attempts)

    {:noreply, handle_validation(socket, pin_result)}
  end

  # Fallback function if the pin wasn't yet 6 digits.
  def handle_event("validate_pin", _, socket), do: {:noreply, socket}

  def handle_event("resend", _, socket) do
    user = socket.assigns[:auth_user]

    if user do
      pin = UserPin.create_pin(user)
      UserMailer.deliver_passwordless_pin(user, pin)
      Accounts.user_lifecycle_action("after_passwordless_pin_sent", user, %{pin: pin})

      {:noreply,
       assign(socket, %{
         enable_resend?: false,
         error_message: nil
       })}
    else
      {:noreply, socket}
    end
  end

  defp send_pin(socket, email) do
    email = Util.trim(email)

    with {:ok, user} <- Accounts.get_or_create_user(%{email: email}, "passwordless"),
         pin when not is_nil(pin) <- UserPin.create_pin(user) do
      {:ok, email} = UserMailer.deliver_passwordless_pin(user, pin)
      Accounts.user_lifecycle_action("after_passwordless_pin_sent", user, %{pin: pin})

      {:noreply,
       socket
       |> assign(%{
         email: email,
         error_message: nil,
         auth_user: user,
         attempts: 0
       })
       |> push_patch(to: ~p"/auth/sign-in/passwordless/enter-pin/#{encode_user_id(user.id)}")}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      _ ->
        {:noreply, assign(socket, error_message: gettext("Unknown error."))}
    end
  end

  defp decode_user_id(hashed_user_id), do: Util.HashId.decode(hashed_user_id, salt_addition: @hash_salt)

  defp encode_user_id(user_id), do: Util.HashId.encode(user_id, salt_addition: @hash_salt)

  defp build_token_changeset(params) do
    types = %{
      pin: :number,
      sign_in_token: :string,
      user_return_to: :string
    }

    Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
  end

  defp handle_validation(socket, {:ok, _user_pin}) do
    Accounts.UserPin.purge_pins(socket.assigns.auth_user)

    sign_in_token =
      socket.assigns.auth_user
      |> Accounts.generate_user_session_token()
      |> Base.encode64()

    token_changeset =
      build_token_changeset(%{
        sign_in_token: sign_in_token,
        user_return_to: socket.assigns.user_return_to
      })

    Process.send_after(self(), :trigger_submit, 500)

    assign(socket, token_form: to_form(token_changeset, as: :auth), loading: true)
  end

  defp handle_validation(socket, {:error, :too_many_incorrect_attempts}) do
    Accounts.UserPin.purge_pins(socket.assigns.auth_user)

    PetalPro.Logs.log_async("passwordless_pin_too_many_incorrect_attempts", %{
      user: socket.assigns.auth_user
    })

    socket
    |> push_patch(to: ~p"/auth/sign-in/passwordless")
    |> put_flash(:error, gettext("Too many incorrect attempts."))
  end

  defp handle_validation(socket, {:error, :expired}) do
    Accounts.UserPin.purge_pins(socket.assigns.auth_user)

    PetalPro.Logs.log_async("passwordless_pin_expired", %{
      user: socket.assigns.auth_user
    })

    socket
    |> push_patch(to: ~p"/auth/sign-in/passwordless")
    |> put_flash(:error, gettext("Not a valid pin. Sure you typed it correctly?"))
  end

  defp handle_validation(socket, {:error, :incorrect_pin}) do
    # Increase attempt count
    Accounts.UserPin.failed_attempt(socket.assigns.auth_user)

    socket
    |> assign(:error_message, gettext("Not a valid pin. Sure you typed it correctly?"))
    |> assign(:enable_resend?, true)
  end

  defp handle_validation(socket, {:error, :not_found}) do
    socket
    |> push_patch(to: ~p"/auth/sign-in/passwordless")
    |> put_flash(:error, gettext("Not a valid pin. Sure you typed it correctly?"))
  end

  def handle_info(:trigger_submit, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  # Leave this in for testing purposes. Swoosh sends the email back to the live view and allows us to get the pin in the test
  def handle_info({:email, _email}, socket) do
    {:noreply, socket}
  end
end
