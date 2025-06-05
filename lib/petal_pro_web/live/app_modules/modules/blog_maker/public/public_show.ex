defmodule PetalProWeb.BlogMakerLive.PublicShow do
  @moduledoc false
  use PetalProWeb, :live_view

  alias PetalPro.AppModules.BlogMaker.Queries.Posts
  alias PetalPro.Orgs

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"org_slug" => org_slug, "post_slug" => post_slug}, _, socket) do
    org = Orgs.get_org!(org_slug)
    post = Posts.get_live_post_by_slug!(org.id, post_slug)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:org_slug, org_slug)
     |> assign(:post, post)
     |> assign(:related_posts, get_related_posts(post, org.id))}
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

  defp get_related_posts(current_post, org_id) do
    Posts.get_related_posts(current_post, org_id, limit: 4)
  end

  defp hero_background_style(post) do
    if post.published_cover do
      "background-image: url('#{post.published_cover}')"
    else
      ""
    end
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"

  defp formatted_duration(post) do
    "#{post.duration} #{pluralise(post.duration)}"
  end

  defp pluralise(1), do: "minute"
  defp pluralise(_duration), do: "minutes"
end
