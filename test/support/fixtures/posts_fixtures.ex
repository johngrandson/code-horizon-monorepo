defmodule PetalPro.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.Posts` context.
  """

  alias PetalPro.AccountsFixtures

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    admin_user = AccountsFixtures.admin_fixture()

    {:ok, %{post: post}} =
      attrs
      |> Enum.into(%{
        category: "some category",
        title: "some title",
        slug: "some slug",
        cover: "some cover",
        cover_caption: "some cover_caption",
        summary: "some summary",
        content: "{\"blocks\": []}",
        duration: 1,
        author_id: admin_user.id
      })
      |> PetalPro.Posts.create_post()

    Map.put(post, :author, admin_user)
  end

  @doc """
  Generate a post.
  """
  def published_post_fixture(attrs \\ %{}) do
    admin_user = AccountsFixtures.admin_fixture()

    {:ok, %{post: post}} =
      attrs
      |> Enum.into(%{
        category: "some category",
        title: "some title",
        slug: "some slug",
        cover: "some cover",
        cover_caption: "some cover_caption",
        summary: "some summary",
        content: "{\"blocks\": []}",
        duration: 1,
        author_id: admin_user.id
      })
      |> PetalPro.Posts.create_post()

    {:ok, published_post} =
      PetalPro.Posts.publish_post(post, %{
        go_live: DateTime.utc_now()
      })

    Map.put(published_post, :author, admin_user)
  end
end
