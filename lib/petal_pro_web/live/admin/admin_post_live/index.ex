defmodule PetalProWeb.AdminPostLive.Index do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent
  import PetalProWeb.PageComponents

  alias PetalPro.Posts
  alias PetalPro.Posts.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :posts, Posts.list_posts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Posts.get_post!(id))
  end

  defp apply_action(socket, :publish, %{"id" => id}) do
    socket
    |> assign(:page_title, "Publish Post")
    |> assign(:post, Posts.get_post!(id))
  end

  defp apply_action(socket, :new, _params) do
    current_user = socket.assigns.current_user

    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{author_id: current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Blog")
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({PetalProWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Posts.get_post!(id)
    {:ok, _} = Posts.delete_post(post)

    socket = put_flash(socket, :info, "Post deleted")

    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/posts")}
  end

  defp is_live(post) do
    post.go_live && DateTime.compare(post.go_live, DateTime.utc_now()) in [:lt, :eq]
  end
end
