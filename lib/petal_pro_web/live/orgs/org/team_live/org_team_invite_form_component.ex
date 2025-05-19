defmodule PetalProWeb.OrgTeamLive.OrgTeamInviteFormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal max_width="sm" title={@page_title}>
        <.form
          id="form-invite"
          for={@form}
          phx-submit="invite"
          phx-change="validate"
          phx-target={@myself}
        >
          <.field
            type="email"
            field={@form[:email]}
            label={gettext("Email")}
            placeholder={gettext("eg. john@gmail.com")}
            phx-debounce="blur"
          />

          <div class="flex justify-end">
            <.button phx-disable-with={gettext("Inviting...")}>{gettext("Invite")}</.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Orgs.Invitation.changeset(%Orgs.Invitation{}, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"invitation" => params}, socket) do
    changeset =
      socket.assigns.current_org
      |> Orgs.build_invitation(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("invite", %{"invitation" => params}, socket) do
    org = socket.assigns.current_org
    current_user = socket.assigns.current_user

    case Orgs.send_org_invitation(org, current_user, params) do
      {:ok, %{invitation: invitation}} ->
        PetalPro.Logs.log("orgs.create_invitation", %{
          user: socket.assigns.current_user,
          target_user_id: nil,
          org_id: org.id,
          metadata: %{
            email: invitation.email
          }
        })

        {:noreply,
         socket
         |> put_flash(:info, gettext("Invitation sent successfully"))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
