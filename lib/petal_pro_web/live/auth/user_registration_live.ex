defmodule PetalProWeb.UserRegistrationLive do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.Accounts
  alias PetalPro.Accounts.User

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign_form(%User{})

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  def render(assigns) do
    ~H"""
    <.auth_layout title="Register">
      <:logo>
        <.logo_icon class="w-20 h-20" />
      </:logo>
      <:top_links>
        {gettext("Already registered?")}
        <.link class="text-blue-600 underline" navigate={~p"/auth/sign-in"}>
          {gettext("Sign in")}
        </.link>
      </:top_links>
      <.auth_providers or_location="bottom" conn_or_socket={@socket} />

      <.form
        id="registration_form"
        for={@form}
        action={~p"/auth/sign-in?_action=registered"}
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        method="post"
      >
        <div :if={@form.source.action == :insert}>
          <.alert
            color="danger"
            label={gettext("Oops, something went wrong! Please check the errors below.")}
            class="mb-5"
          />
        </div>

        <.field
          field={@form[:name]}
          placeholder={gettext("eg. Sarah Smith")}
          phx-debounce="blur"
          required
        />
        <.field
          type="email"
          field={@form[:email]}
          placeholder={gettext("eg. sarah@gmail.com")}
          phx-debounce="blur"
          autocomplete="username"
          required
        />
        <.field
          type="password"
          phx-debounce="blur"
          value={@form[:password].value}
          field={@form[:password]}
          autocomplete="new-password"
        />
        <div class="flex justify-end mt-6">
          <.button
            label={gettext("Create account")}
            phx-disable-with={gettext("Creating account...")}
          />
        </div>
      </.form>
    </.auth_layout>
    """
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        case Accounts.deliver_user_confirmation_instructions(
               user,
               &url(~p"/auth/confirm/#{&1}")
             ) do
          {:ok, _} ->
            socket =
              socket
              |> assign(trigger_submit: true)
              |> assign_form(user)

            {:noreply, socket}

          {:error, _} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "User has been registered but email delivery failed. Please contact support."
             )}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  defp assign_form(socket, user, changes \\ %{}) do
    assign(socket, form: to_form(Accounts.change_user_registration(user, changes)))
  end
end
