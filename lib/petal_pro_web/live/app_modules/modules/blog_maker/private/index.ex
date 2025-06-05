defmodule PetalProWeb.BlogMakerLive.Index do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AppModulesLayoutComponent
  import PetalProWeb.PageComponents
  import Phoenix.LiveView

  alias PetalPro.AppModules.BlogMaker.Post
  alias PetalPro.AppModules.BlogMaker.Queries.Posts

  @impl true
  def mount(_params, _session, socket) do
    posts = Posts.list_posts(socket.assigns.current_org.id)

    socket =
      socket
      |> stream(:posts, posts)
      |> assign(:stream_items_count, Enum.count(posts))
      |> assign(:stream_empty, Enum.empty?(posts))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Post"))
    |> assign(:post, Posts.get_post!(socket.assigns.org_id, id))
  end

  defp apply_action(socket, :publish, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Publish Post"))
    |> assign(:post, Posts.get_post!(socket.assigns.org_id, id))
  end

  defp apply_action(socket, :new, _params) do
    current_user = socket.assigns.current_user

    socket
    |> assign(:page_title, gettext("New Post"))
    |> assign(:post, %Post{author_id: current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Blog"))
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({PetalProWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Posts.get_post!(socket.assigns.org_id, id)
    {:ok, _} = Posts.delete_post(post)

    socket = put_flash(socket, :info, gettext("Post deleted"))

    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/org/#{socket.assigns.org_slug}/blog-maker")}
  end

  defp is_live(post) do
    post.go_live && DateTime.compare(post.go_live, DateTime.utc_now()) in [:lt, :eq]
  end
end
