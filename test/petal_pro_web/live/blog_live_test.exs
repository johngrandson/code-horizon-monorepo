defmodule PetalProWeb.BlogLiveTest do
  # use PetalProWeb.ConnCase

  # import PetalPro.PostsFixtures
  # import Phoenix.LiveViewTest

  # alias PetalPro.Posts

  # defp publish_post(_) do
  #   published_post = published_post_fixture()

  #   %{published_post: published_post}
  # end

  # describe "Index" do
  #   setup [:publish_post]

  #   test "list published blog items", %{conn: conn, published_post: published_post} do
  #     {:ok, index_live, html} = live(conn, ~p"/blog")

  #     assert has_element?(index_live, "h2", "Articles, Tips and Tutorials")
  #     assert html =~ published_post.category
  #     assert html =~ Integer.to_string(published_post.duration) <> " minute"
  #     assert html =~ PetalProWeb.Helpers.user_name(published_post.author)
  #     refute html =~ "Coming soon"
  #   end

  #   test "no blog list items", %{conn: conn, published_post: published_post} do
  #     {:ok, post} = Posts.unpublish_post(published_post)
  #     {:ok, index_live, html} = live(conn, ~p"/blog")

  #     assert has_element?(index_live, "h2", "Articles, Tips and Tutorials")
  #     assert html =~ "No blog posts!"
  #     refute html =~ post.category
  #   end

  #   test "read only blog list for user", %{conn: conn} do
  #     {:ok, index_live, _html} = live(conn, ~p"/blog")

  #     refute has_element?(index_live, "a", "Posts")
  #     refute has_element?(index_live, "a", "New Post")
  #   end

  #   test "editable blog list for admin user", %{conn: conn} do
  #     %{conn: conn} = register_and_sign_in_admin(%{conn: conn})
  #     {:ok, index_live, _html} = live(conn, ~p"/blog")

  #     assert has_element?(index_live, "a", "Articles, Tips and Tutorials")
  #   end
  # end

  # describe "Show" do
  #   setup [:publish_post]

  #   test "show published blog", %{conn: conn, published_post: published_post} do
  #     {:ok, show_live, html} = live(conn, ~p"/blog/#{published_post.slug}")

  #     assert has_element?(show_live, "h1", published_post.title)
  #     assert html =~ published_post.category
  #     assert html =~ published_post.cover
  #     assert html =~ published_post.cover_caption
  #     assert html =~ Integer.to_string(published_post.duration) <> " minute"
  #     assert html =~ published_post.summary
  #     assert html =~ PetalProWeb.Helpers.user_name(published_post.author)
  #   end

  #   test "can't show unpublished blog", %{conn: conn, published_post: published_post} do
  #     {:ok, post} = Posts.unpublish_post(published_post)

  #     assert {:error, {:redirect, %{to: "/blog", flash: flash}}} = live(conn, ~p"/blog/#{post.slug}")

  #     assert flash["error"] =~ "Blog post not found"
  #   end

  #   test "read only blog for user", %{conn: conn, published_post: published_post} do
  #     {:ok, show_live, _html} = live(conn, ~p"/blog/#{published_post.slug}")

  #     refute has_element?(show_live, "a", "Edit Post")
  #   end

  #   test "editable blog for admin user", %{conn: conn, published_post: published_post} do
  #     %{conn: conn} = register_and_sign_in_admin(%{conn: conn})
  #     {:ok, show_live, _html} = live(conn, ~p"/blog/#{published_post.slug}")

  #     assert has_element?(show_live, "a", "Edit Post")
  #   end

  #   test "handles invalid hashid in URL", %{conn: conn} do
  #     assert {:error, {:redirect, %{to: "/blog", flash: flash}}} =
  #              live(conn, ~p"/blog/invalid-hashid-your_zgenimc6etcy0gnl")

  #     assert flash["error"] =~ "Blog post not found"
  #   end

  #   test "handles non-existent post ID", %{conn: conn} do
  #     # Create and then delete a post to ensure we have a valid hashid but no record
  #     post = published_post_fixture()
  #     {:ok, _} = Posts.delete_post(post)

  #     assert {:error, {:redirect, %{to: "/blog", flash: flash}}} =
  #              live(conn, ~p"/blog/#{post.slug}")

  #     assert flash["error"] =~ "Blog post not found"
  #   end
  # end
end
