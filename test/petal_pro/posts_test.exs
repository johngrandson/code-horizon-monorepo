defmodule PetalPro.PostsTest do
  use PetalPro.DataCase

  alias PetalPro.Posts

  describe "posts" do
    import PetalPro.AccountsFixtures
    import PetalPro.PostsFixtures

    alias PetalPro.Posts.Post

    @invalid_attrs %{
      category: nil,
      content: nil,
      cover: nil,
      cover_caption: nil,
      duration: nil,
      last_published: nil,
      go_live: nil,
      published_category: nil,
      published_content: nil,
      published_cover: nil,
      published_cover_caption: nil,
      published_duration: nil,
      published_slug: nil,
      published_summary: nil,
      published_title: nil,
      slug: nil,
      summary: nil,
      title: nil
    }

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Posts.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Posts.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      user = user_fixture()

      valid_attrs = %{
        category: "some category",
        title: "some title",
        slug: "some slug",
        cover: "some cover",
        cover_caption: "some cover_caption",
        summary: "some summary",
        content: "some content",
        duration: 1,
        last_published: ~N[2024-10-30 03:20:00],
        go_live: ~U[2024-10-30 03:20:00Z],
        published_category: "some published_category",
        published_title: "some published_title",
        published_slug: "some published_slug",
        published_cover: "some published_cover",
        published_cover_caption: "some published_cover_caption",
        published_summary: "some published_summary",
        published_content: "some published_content",
        published_duration: 2,
        author_id: user.id
      }

      assert {:ok, %{post: %Post{} = post}} = Posts.create_post(valid_attrs)
      assert post.category == "some category"
      assert post.title == "some title"
      assert post.slug =~ "some-title-"
      assert post.cover == "some cover"
      assert post.cover_caption == "some cover_caption"
      assert post.summary == "some summary"
      assert post.content == "some content"
      assert post.duration == 1

      assert post.published_category == nil
      assert post.published_title == nil
      assert post.published_slug == nil
      assert post.published_cover == nil
      assert post.published_cover_caption == nil
      assert post.published_content == nil
      assert post.published_summary == nil
      assert post.published_duration == nil
      assert post.last_published == nil
      assert post.go_live == nil
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, :insert_post, %Ecto.Changeset{}, _changes} = Posts.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()

      update_attrs = %{
        category: "some updated category",
        title: "some updated title",
        slug: "some updated slug",
        cover: "some updated cover",
        cover_caption: "some updated cover_caption",
        summary: "some updated summary",
        content: "some updated content",
        duration: 1,
        published_category: "some updated published_category",
        published_title: "some updated published_title",
        published_slug: "some updated published_slug",
        published_cover: "some updated published_cover",
        published_cover_caption: "some updated published_cover_caption",
        published_summary: "some updated published_summary",
        published_content: "some updated published_content",
        published_duration: 2,
        last_published: ~N[2024-10-31 03:20:00],
        go_live: ~U[2024-10-31 03:20:00Z]
      }

      assert {:ok, %Post{} = post} = Posts.update_post(post, update_attrs)
      assert post.category == "some updated category"
      assert post.title == "some updated title"
      assert post.slug =~ "some-updated-title"
      assert post.cover == "some updated cover"
      assert post.cover_caption == "some updated cover_caption"
      assert post.summary == "some updated summary"
      assert post.content == "some updated content"
      assert post.duration == 1

      assert post.published_category == nil
      assert post.published_title == nil
      assert post.published_slug == nil
      assert post.published_cover == nil
      assert post.published_cover_caption == nil
      assert post.published_summary == nil
      assert post.published_content == nil
      assert post.published_duration == nil

      assert post.last_published == nil
      assert post.go_live == nil
    end

    test "publish_post/2 updates the post" do
      post = post_fixture()

      assert post.published_category == nil
      assert post.published_title == nil
      assert post.published_slug == nil
      assert post.published_cover == nil
      assert post.published_cover_caption == nil
      assert post.published_summary == nil
      assert post.published_content == nil
      assert post.published_duration == nil

      assert post.last_published == nil
      assert post.go_live == nil

      go_live = DateTime.utc_now()
      assert {:ok, %Post{} = post} = Posts.publish_post(post, %{go_live: go_live})

      assert post.published_category == post.category
      assert post.published_title == post.title
      assert post.published_slug == post.slug
      assert post.published_cover == post.cover
      assert post.published_cover_caption == post.cover_caption
      assert post.published_summary == post.summary
      assert post.published_content == post.content
      assert post.published_duration == post.duration
      assert post.last_published != nil
      assert post.go_live == DateTime.truncate(go_live, :second)
    end

    test "publish_post/2 with valid data updates the post" do
      post = post_fixture()

      assert post.published_category == nil
      assert post.published_title == nil
      assert post.published_slug == nil
      assert post.published_cover == nil
      assert post.published_cover_caption == nil
      assert post.published_summary == nil
      assert post.published_content == nil
      assert post.published_duration == nil

      assert post.last_published == nil
      assert post.go_live == nil

      attrs = %{
        category: "new category",
        title: "new title",
        slug: "new-title-xxxx",
        cover: "new_cover_image.jpg",
        cover_caption: "new cover caption",
        summary: "new summary",
        content: "new content",
        duration: 2,
        go_live: DateTime.utc_now()
      }

      assert {:ok, %Post{} = post} = Posts.publish_post(post, attrs)

      assert post.published_category == "new category"
      assert post.published_title == "new title"
      assert post.published_slug == "new-title-xxxx"
      assert post.published_cover == "new_cover_image.jpg"
      assert post.published_cover_caption == "new cover caption"
      assert post.published_summary == "new summary"
      assert post.published_content == "new content"
      assert post.published_duration == 2
      assert post.last_published != nil
      assert post.go_live == DateTime.truncate(attrs.go_live, :second)
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, @invalid_attrs)
      assert post == Posts.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Posts.change_post(post)
    end
  end
end
