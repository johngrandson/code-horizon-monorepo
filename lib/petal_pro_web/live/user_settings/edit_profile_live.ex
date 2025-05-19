defmodule PetalProWeb.EditProfileLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.UserSettingsLayoutComponent

  alias PetalPro.Accounts
  alias PetalPro.Accounts.User
  alias PetalProWeb.FileUploadComponents

  # SETUP_TODO: pick a storage option for images below.
  # Cloudinary setup info: /lib/petal_pro/file_uploads/cloudinary.ex
  # S3 setup info: /lib/petal_pro/file_uploads/s3.ex
  # We recommend cloudinary due to its ability to optimize and transform images based on URL parameters
  # For non-image files, we recommend S3

  @upload_provider PetalPro.FileUploads.Local
  # @upload_provider PetalPro.FileUploads.Cloudinary
  # @upload_provider PetalPro.FileUploads.S3

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(%{
        page_title: "Settings",
        uploaded_files: []
      })
      |> assign_form(socket.assigns.current_user)
      |> allow_upload(:avatar,
        # SETUP_TODO: Uncomment the line below if using an external provider (Cloudinary or S3)
        # external: &@upload_provider.presign_upload/2,
        accept: ~w(.jpg .jpeg .png .gif .svg .webp),
        max_entries: 1
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.settings_layout current_page={:edit_profile} current_user={@current_user}>
      <.form id="update_profile_form" for={@form} phx-submit="submit" phx-change="validate">
        <FileUploadComponents.image_input
          upload={@uploads.avatar}
          label={gettext("Avatar")}
          current_image_src={user_avatar_url(@current_user)}
          placeholder_icon="hero-user-solid"
          on_delete="clear_avatar"
          automatic_help_text
        />

        <.field field={@form[:name]} label={gettext("Name")} placeholder={gettext("eg. John Smith")} />

        <div class="flex justify-end">
          <.button>{gettext("Update profile")}</.button>
        </div>
      </.form>
    </.settings_layout>
    """
  end

  @impl true
  def handle_event("submit", %{"user" => user_params}, socket) do
    user_params = maybe_add_avatar(user_params, socket)
    update_profile(socket, user_params)
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("clear_avatar", _params, socket) do
    update_profile(socket, %{avatar: nil})
  end

  defp update_profile(socket, user_params) do
    case Accounts.update_profile(socket.assigns.current_user, user_params) do
      {:ok, current_user} ->
        Accounts.user_lifecycle_action("after_update_profile", current_user)

        socket =
          socket
          |> put_flash(:info, gettext("Profile updated"))
          |> assign(current_user: current_user)
          |> assign_form(current_user)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Update failed. Please check the form for issues"))
          |> assign(form: to_form(changeset))

        {:noreply, socket}
    end
  end

  def maybe_add_avatar(user_params, socket) do
    uploaded_files = @upload_provider.consume_uploaded_entries(socket, :avatar)

    if length(uploaded_files) > 0 do
      Map.put(user_params, "avatar", hd(uploaded_files))
    else
      user_params
    end
  end

  defp assign_form(socket, user) do
    assign(socket, form: to_form(User.profile_changeset(user)))
  end
end
