defmodule PetalProWeb.AdminFilesLive.FormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Files
  alias PetalPro.Files.File
  alias PetalProWeb.FileUploadComponents

  @upload_provider PetalPro.FileUploads.Local
  # @upload_provider PetalPro.FileUploads.Cloudinary
  # @upload_provider PetalPro.FileUploads.S3

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> %File{} |> Files.change_file() |> to_form() end)
      |> assign(:uploaded_files, [])
      |> allow_upload(:new_file,
        # SETUP_TODO: Uncomment the line below if using an external provider (Cloudinary or S3)
        # external: &@upload_provider.presign_upload/2,
        accept: ~w(.jpg .jpeg .png .gif .svg .webp),
        max_entries: 1
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"file" => file_params}, socket) do
    uploaded_files = @upload_provider.consume_uploaded_entries(socket, :new_file)

    socket = update(socket, :uploaded_files, &(&1 ++ uploaded_files))

    file_params =
      if length(uploaded_files) > 0 do
        Map.put(file_params, "url", hd(uploaded_files))
      else
        file_params
      end

    create_file(socket, file_params)
  end

  @impl true
  def handle_event("validate", %{"_target" => ["new_file"], "file" => file_params}, socket) do
    uploads = socket.assigns.uploads
    file_entry = hd(uploads.new_file.entries)

    file_params =
      Map.update(file_params, "name", "", fn existing ->
        if existing === "" do
          file_entry.client_name
        else
          existing
        end
      end)

    changeset =
      %File{}
      |> Files.change_file(file_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :new_file, ref)}
  end

  defp create_file(socket, file_params) do
    case Files.create_file(file_params) do
      {:ok, _new_file} ->
        notify_parent(:file_added)

        form =
          %File{}
          |> Files.change_file()
          |> to_form()

        {:noreply, assign(socket, :form, form)}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Update failed. Please check the form for issues"))
          |> assign(form: to_form(changeset))

        {:noreply, socket}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
