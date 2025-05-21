defmodule PetalProWeb.AdminPostLive.PublishComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.Posts

  @impl true
  def update(%{post: post} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Posts.change_post(post))
     end)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Posts.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  @impl true
  def handle_event("unpublish", _, socket) do
    case Posts.unpublish_post(socket.assigns.post) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Post is no longer publically available"))
         |> push_patch(to: ~p"/admin/posts/#{post.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :publish, post_params) do
    case Posts.publish_post(socket.assigns.post, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Post published successfully"))
         |> push_navigate(to: ~p"/admin/posts/#{post.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
