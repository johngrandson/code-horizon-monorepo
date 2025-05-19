defmodule PetalProWeb.AdminPostLive.NewComponent do
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

  defp save_post(socket, :new, post_params) do
    case Posts.create_post(post_params) do
      {:ok, %{post: post}} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully")
         |> push_navigate(to: ~p"/admin/posts/#{post}/show/edit")}

      {:error, :insert_post, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
