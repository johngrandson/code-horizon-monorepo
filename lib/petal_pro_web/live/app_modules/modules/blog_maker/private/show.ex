defmodule PetalProWeb.BlogMakerLive.Show do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AppModulesLayoutComponent
  import PetalProWeb.PageComponents

  alias PetalPro.AppModules.BlogMaker.Queries.Posts
  alias PetalPro.Files
  alias PetalPro.Orgs

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    org = Orgs.get_org!(params["org_slug"])

    socket =
      socket
      |> assign(:org_slug, params["org_slug"])
      |> assign(:org_id, org.id)
      |> assign(:post_id, params["id"])

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Post")
    |> assign(:post, Posts.get_post!(socket.assigns.org_id, id))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Posts.get_post!(socket.assigns.org_id, id))
    |> assign(:image_target, nil)
    |> assign(:files, nil)
  end

  defp apply_action(socket, :files, %{"id" => id, "image_target" => image_target}) do
    socket
    |> assign(:page_title, "Upload or select file")
    |> assign(:post, Posts.get_post!(socket.assigns.org_id, id))
    |> assign(:image_target, image_target)
    |> assign(:files, Files.list_files())
  end

  defp apply_action(socket, :publish, %{"id" => id}) do
    socket
    |> assign(:page_title, "Publish Post")
    |> assign(:post, Posts.get_post!(socket.assigns.org_id, id))
  end

  @impl true
  def handle_event("show_files", %{"image-target" => image_target}, socket) do
    files = ~p"/app/org/#{socket.assigns.org_slug}/blog-maker/#{socket.assigns.post.id}/show/edit/files/#{image_target}"

    {:noreply, push_patch(socket, to: files)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/org/#{socket.assigns.org_slug}/blog-maker")}
  end

  @impl true
  def handle_event("delete_post", params, socket) do
    post = Posts.get_post!(socket.assigns.org_id, params["id"])

    case Posts.delete_post(post) do
      {:ok, _post} ->
        socket =
          socket
          |> put_flash(:info, gettext("Post deleted"))
          |> push_navigate(to: ~p"/app/org/#{socket.assigns.org_slug}/blog-maker")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({PetalProWeb.BlogMakerLive.FormComponent, :file_added}, socket) do
    {:noreply, assign(socket, :files, Files.list_files())}
  end

  @impl true
  def handle_info({PetalProWeb.BlogMakerLive.FilesComponent, :file_archived}, socket) do
    {:noreply, assign(socket, :files, Files.list_files())}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  defp is_live(post) do
    post.go_live && DateTime.compare(post.go_live, DateTime.utc_now()) in [:lt, :eq]
  end

  defp not_live_yet(post) do
    post.go_live && DateTime.after?(post.go_live, DateTime.utc_now())
  end

  defp formatted_duration(post) do
    "#{post.duration} #{pluralise(post.duration)}"
  end

  defp pluralise(1), do: "minute"
  defp pluralise(_duration), do: "minutes"
end
