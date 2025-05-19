defmodule PetalProWeb.BlogLive.Show do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.PageComponents

  alias PetalPro.Posts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    post = Posts.get_live_post_by_slug!(slug)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)}
  rescue
    [Ecto.NoResultsError, Hashids.DecodingError] ->
      {:noreply,
       socket
       |> put_flash(:error, "Blog post not found")
       |> redirect(to: ~p"/blog")}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/blog/#{socket.assigns.post}")}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"

  defp formatted_duration(post) do
    "#{post.duration} #{pluralise(post.duration)}"
  end

  defp pluralise(1), do: "minute"
  defp pluralise(_duration), do: "minutes"
end
