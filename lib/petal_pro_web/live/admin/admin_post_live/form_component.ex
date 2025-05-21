defmodule PetalProWeb.AdminPostLive.FormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Posts

  @autosave_delay 500

  @impl true
  def update(%{post: post} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(autosave_delay: @autosave_delay)
     |> assign_new(:form, fn ->
       to_form(Posts.change_post(post))
     end)
     |> assign(:saved_at, nil)
     |> assign(:saving, false)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    form =
      socket.assigns.post
      |> Posts.change_post(post_params)
      |> to_form(action: :validate)

    socket = assign(socket, form: form)

    if form.source.valid? do
      save_changes(socket, post_params)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    post = socket.assigns.post

    case Posts.update_post(post, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Post updated successfully"))
         |> push_navigate(to: ~p"/admin/posts/#{post.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/posts/#{socket.assigns.post}/show/edit")}
  end

  @impl true
  def handle_event("select_file", %{"image-target" => "cover"} = file_params, socket) do
    post_params = %{cover: file_params["url"], cover_caption: file_params["name"]}

    form =
      socket.assigns.form.source
      |> Ecto.Changeset.change(post_params)
      |> to_form(action: :validate)

    socket =
      socket
      |> assign(form: form)
      |> push_patch(to: ~p"/admin/posts/#{socket.assigns.post}/show/edit")

    if form.source.valid? do
      save_changes(socket, post_params)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_file", file_params, socket) do
    {:noreply,
     socket
     |> push_event("select_file", file_params)
     |> push_patch(to: ~p"/admin/posts/#{socket.assigns.post}/show/edit")}
  end

  @impl true
  def handle_async(:form_save, {:ok, {:ok, post}}, socket) do
    notify_parent({:saved, post})

    {:noreply,
     socket
     |> assign(:saving, false)
     |> assign(:saved_at, DateTime.utc_now())}
  end

  @impl true
  def handle_async(:form_save, {:ok, {:error, changeset}}, socket) do
    {:noreply,
     socket
     |> assign(:saving, false)
     |> assign(form: to_form(changeset))}
  end

  @impl true
  def handle_async(:form_save, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:saving, false)
     |> put_flash(:error, "Save operation failed unexpectedly: #{inspect(reason)}")}
  end

  defp save_changes(socket, post_params) do
    post = socket.assigns.post

    if socket.assigns.saving do
      cancel_async(socket, :form_save)
    end

    socket =
      socket
      |> assign(:saving, true)
      |> start_async(:form_save, fn ->
        Posts.update_post(post, post_params)
      end)

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
