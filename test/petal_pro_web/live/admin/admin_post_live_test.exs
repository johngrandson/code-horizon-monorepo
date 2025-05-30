defmodule PetalProWeb.AdminPostLiveTest do
  # use PetalProWeb.ConnCase

  # import PetalPro.PostsFixtures
  # import Phoenix.LiveViewTest

  # alias PetalPro.Posts

  # @create_attrs %{
  #   category: "some category",
  #   summary: "some summary",
  #   title: "some title"
  # }
  # @update_attrs %{
  #   category: "some updated category",
  #   content: "{\"blocks\": []}",
  #   cover_caption: "some updated cover_caption",
  #   duration: 2,
  #   summary: "some updated summary",
  #   title: "some updated title"
  # }
  # @invalid_attrs %{
  #   category: nil,
  #   summary: nil,
  #   title: nil
  # }

  # @publish_attrs %{
  #   go_live: DateTime.utc_now()
  # }

  # @publish_future_attrs %{
  #   go_live: DateTime.add(DateTime.utc_now(), 1, :day)
  # }

  # @invalid_publish_attrs %{
  #   go_live: nil
  # }

  # defp create_post(_) do
  #   post = post_fixture()
  #   %{post: post}
  # end

  # describe "Index" do
  #   setup [:register_and_sign_in_admin, :create_post]

  #   test "lists all posts", %{conn: conn, post: post} do
  #     {:ok, _index_live, html} = live(conn, ~p"/admin/posts")

  #     assert html =~ "Posts"
  #     assert html =~ post.category
  #   end

  #   test "show unprocessed post", %{conn: conn, post: post} do
  #     {:ok, index_live, html} = live(conn, ~p"/admin/posts")

  #     assert html =~ "Posts"
  #     refute has_element?(index_live, "#processed-posts-#{post.id}")
  #     refute has_element?(index_live, "#publish-posts-#{post.id}")
  #   end

  #   test "show published post", %{conn: conn, post: post} do
  #     {:ok, post} = Posts.publish_post(post, @publish_attrs)

  #     {:ok, index_live, _html} = live(conn, ~p"/admin/posts")

  #     assert has_element?(index_live, "#processed-#{post.id}")
  #     assert has_element?(index_live, "#published-#{post.id}")
  #   end

  #   test "show unpublished post", %{conn: conn, post: post} do
  #     {:ok, post} = Posts.publish_post(post, @publish_attrs)
  #     {:ok, post} = Posts.unpublish_post(post)

  #     {:ok, index_live, _html} = live(conn, ~p"/admin/posts")

  #     assert has_element?(index_live, "#processed-#{post.id}")
  #     refute has_element?(index_live, "#published-#{post.id}")
  #   end

  #   test "saves new post and redirects to edit", %{conn: conn} do
  #     {:ok, index_live, _html} = live(conn, ~p"/admin/posts")

  #     assert index_live |> element("a", "New Post") |> render_click() =~
  #              "New Post"

  #     assert_patch(index_live, ~p"/admin/posts/new")

  #     assert index_live
  #            |> form("#new-form", post: @invalid_attrs)
  #            |> render_change() =~ "can&#39;t be blank"

  #     assert index_live
  #            |> form("#new-form", post: @create_attrs)
  #            |> render_submit()

  #     {path, flash} = assert_redirect(index_live)

  #     assert path =~ ~r"/admin/posts/\d+/show/edit"
  #     assert flash["info"] =~ "Post created successfully"

  #     {:ok, _index_live, html} = live(conn, ~p"/admin/posts")
  #     assert html =~ "some category"
  #   end

  #   test "deletes post in listing", %{conn: conn, post: post} do
  #     {:ok, index_live, _html} = live(conn, ~p"/admin/posts")

  #     assert index_live
  #            |> element(
  #              "button[data-confirm*='Are you sure you want to delete the selected posts? This action cannot be undone.']"
  #            )
  #            |> render_click()

  #     refute has_element?(index_live, "#posts-#{post.id}")
  #   end
  # end

  # describe "Show" do
  #   setup [:register_and_sign_in_admin, :create_post]

  #   test "displays post", %{conn: conn, post: post} do
  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert html =~ "Posts"
  #     assert html =~ post.category
  #     assert html =~ post.title
  #     assert html =~ post.cover
  #     assert html =~ post.cover_caption
  #     assert html =~ post.summary
  #   end

  #   test "updates post within modal", %{conn: conn, post: post} do
  #     {:ok, show_live, _html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert show_live |> element("a", "Edit") |> render_click() =~
  #              "Posts"

  #     assert_patch(show_live, ~p"/admin/posts/#{post}/show/edit")

  #     assert show_live
  #            |> form("#post-form", post: @invalid_attrs)
  #            |> render_change() =~ "can&#39;t be blank"

  #     assert show_live
  #            |> form("#post-form", post: @update_attrs)
  #            |> render_submit()

  #     flash = assert_redirect(show_live, ~p"/admin/posts/#{post}")
  #     assert flash["info"] =~ "Post updated successfully"

  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}")
  #     assert html =~ "some updated category"
  #   end

  #   test "deletes post", %{conn: conn, post: post} do
  #     {:ok, show_live, _html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert show_live
  #            |> element("button", "Delete")
  #            |> render_click()

  #     assert_redirect(show_live, ~p"/admin/posts")

  #     {:ok, index_live, _html} = live(conn, ~p"/admin/posts")
  #     refute has_element?(index_live, "#posts-#{post.id}")
  #   end

  #   test "publish post", %{conn: conn, post: post} do
  #     {:ok, show_live, html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert html =~ "Unpublished"

  #     assert show_live |> element("a", "Publish") |> render_click() =~
  #              "Publish"

  #     assert_patch(show_live, ~p"/admin/posts/#{post}/show/publish")

  #     assert show_live
  #            |> form("#publish-form", post: @invalid_publish_attrs)
  #            |> render_submit() =~ "can&#39;t be blank"

  #     valid_publish_attrs = %{
  #       go_live: DateTime.utc_now()
  #     }

  #     assert show_live
  #            |> form("#publish-form", post: valid_publish_attrs)
  #            |> render_submit()

  #     flash = assert_redirect(show_live, ~p"/admin/posts/#{post}")
  #     assert flash["info"] =~ "Post published successfully"

  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}")
  #     assert html =~ "Published"
  #   end

  #   test "unpublish", %{conn: conn, post: post} do
  #     {:ok, post} = Posts.publish_post(post, @publish_attrs)

  #     {:ok, show_live, html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert html =~ "Published"

  #     assert show_live |> element("a", "Publish") |> render_click() =~
  #              "Publish"

  #     assert_patch(show_live, ~p"/admin/posts/#{post}/show/publish")

  #     assert show_live |> element("#publish-form a", "Remove") |> render_click()

  #     assert_patch(show_live, ~p"/admin/posts/#{post}")

  #     assert render(show_live) =~ "Unpublished"
  #   end

  #   test "show unpublished post", %{conn: conn, post: post} do
  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert html =~ "Unpublished"
  #   end

  #   test "show live post", %{conn: conn, post: post} do
  #     {:ok, post} = Posts.publish_post(post, @publish_attrs)

  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert html =~ "Published"
  #     refute html =~ "Live in"
  #   end

  #   test "show future post", %{conn: conn, post: post} do
  #     {:ok, post} = Posts.publish_post(post, @publish_future_attrs)

  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}")

  #     assert html =~ "Published"
  #     assert html =~ "Live in"
  #   end
  # end

  # describe "File Selector" do
  #   import PetalPro.FilesFixtures

  #   alias PetalPro.Files.File

  #   setup [:register_and_sign_in_admin, :create_post]

  #   test "Clicking cover opens file selector", %{conn: conn, post: post} do
  #     {:ok, show_live, _html} = live(conn, ~p"/admin/posts/#{post}/show/edit")

  #     html =
  #       show_live
  #       |> element("a#cover")
  #       |> render_click()

  #     assert Floki.find(html, "input[type=file]") !== []
  #   end

  #   test "File upload and add", %{conn: conn, post: post} do
  #     {:ok, show_live, _html} = live(conn, ~p"/admin/posts/#{post}/show/edit/files/cover")

  #     fake_file = [
  #       %{
  #         last_modified: 1_594_171_879_000,
  #         name: "test.jpg",
  #         content: "Fake file",
  #         size: byte_size("Fake file"),
  #         type: "image/jpeg"
  #       }
  #     ]

  #     file_input = file_input(show_live, "#new-file-form", :new_file, fake_file)

  #     assert render_upload(file_input, "test.jpg") =~ "100%"

  #     file_params = %{
  #       "file" => %{"name" => "test.jpg"}
  #     }

  #     assert show_live
  #            |> form("#new-file-form", file_params)
  #            |> render_submit()

  #     file = PetalPro.Repo.get_by(File, name: "test.jpg")

  #     refute is_nil(file)
  #   end

  #   test "Selecting file updates cover image", %{conn: conn, post: post} do
  #     file = file_fixture()

  #     {:ok, show_live, _html} = live(conn, ~p"/admin/posts/#{post}/show/edit/files/cover")

  #     html = show_live |> element("a[phx-click=select_file]") |> render_click()

  #     assert Floki.find(html, "img[src='#{file.url}']") !== []
  #   end

  #   test "Archiving file removes it from the list", %{conn: conn, post: post} do
  #     file = file_fixture()

  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}/show/edit/files/cover")

  #     assert Floki.find(html, "button[phx-click=archive]") !== []

  #     PetalPro.Files.archive_file(file)

  #     {:ok, _show_live, html} = live(conn, ~p"/admin/posts/#{post}/show/edit/files/cover")

  #     assert Floki.find(html, "button[phx-click=archive]") === []
  #   end
  # end
end
