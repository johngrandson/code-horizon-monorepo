defmodule PetalPro.AppModules.BlogMaker.Queries.Posts do
  @moduledoc """
  The BlogMakerPosts context.
  """

  import Ecto.Query, warn: false

  alias PetalPro.AppModules.BlogMaker.Post
  alias PetalPro.Extensions.MapExt
  alias PetalPro.Repo

  defp live_posts(org_id) do
    utc_now = DateTime.utc_now()

    from p in Post,
      where: p.org_id == ^org_id and not is_nil(p.go_live) and p.go_live <= ^utc_now
  end

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(org_id) do
    query =
      from p in Post,
        where: p.org_id == ^org_id,
        # |> coalesce(p.last_published) |> coalesce(p.updated_at)]
        order_by: [desc: p.inserted_at]

    query
    |> Repo.all()
    |> Repo.preload(:author)
  end

  @doc """
  Returns the list of posts that have been published.

  ## Examples

      iex> list_live_posts()
      [%Post{}, ...]

  """
  def list_live_posts(org_id) do
    query =
      from p in live_posts(org_id),
        order_by: [desc: p.go_live]

    query
    |> Repo.all()
    |> Repo.preload(:author)
  end

  @doc """
  Returns a filtered list of published posts based on the given criteria.

  ## Examples

      iex> list_live_posts_by_filters(category: "all", search: "", limit: 9, org_id: 123)
      [%Post{}, ...]
  """
  def list_live_posts_by_filters(category: category, search: search, limit: limit, org_id: org_id) do
    query =
      from p in live_posts(org_id),
        where: p.published_category == ^category and ilike(p.published_title, ^"%#{search}%"),
        order_by: [desc: p.go_live],
        limit: ^limit

    query
    |> Repo.all()
    |> Repo.preload(:author)
  end

  def get_related_posts(current_post, org_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 4)

    Repo.all(
      from(p in Post,
        where: p.org_id == ^org_id and p.id != ^current_post.id and p.last_published <= ^DateTime.utc_now(),
        where: not is_nil(p.last_published),
        order_by: [desc: p.last_published],
        limit: ^limit,
        select: [:id, :published_title, :published_slug, :published_cover, :published_summary, :published_duration]
      )
    )
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(org_id, id) do
    Post
    |> where([p], p.org_id == ^org_id and p.id == ^id)
    |> Repo.get!(id)
    |> Repo.preload(:author)
    |> Repo.preload(:org)
  end

  @doc """
  Gets a single post if it has been published.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_live_post!(123)
      %Post{}

      iex> get_live_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_live_post!(id, org_id) do
    org_id
    |> live_posts()
    |> Repo.get!(id)
    |> Repo.preload(:author)
    |> Repo.preload(:org)
  end

  @doc """
  Gets a single post using a slug.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post_by_slug!("post-stub")
      %Post{}

      iex> get_post_by_slug!("post-stub-x3kF04k")
      %Post{}

      iex> get_post_by_slug!("does-not-exist")
      ** (Ecto.NoResultsError)

  """
  def get_post_by_slug!(org_id, slug) do
    Post
    |> where([p], p.org_id == ^org_id and p.slug == ^slug)
    |> Repo.get_by(slug: slug)
    |> Repo.preload(:author)
    |> case do
      nil ->
        get_post!(org_id, Post.extract_id_from_slug(slug))

      post ->
        post
    end
  end

  @doc """
  Gets a single post using a slug.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post_by_slug!("post-stub")
      %Post{}

      iex> get_post_by_slug!("post-stub-x3kF04k")
      %Post{}

      iex> get_post_by_slug!("does-not-exist")
      ** (Ecto.NoResultsError)

  """
  def get_live_post_by_slug!(org_id, slug) do
    org_id
    |> live_posts()
    |> Repo.get_by(published_slug: slug)
    |> Repo.preload(:author)
    |> case do
      nil ->
        # This will happen if an old url has been copied and pasted. It will also
        # happen when coming from the admin console to the blog
        get_live_post!(Post.extract_id_from_slug(slug), org_id)

      post ->
        post
    end
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    changeset = Post.changeset(%Post{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_post, changeset)
    |> Ecto.Multi.update(:post, fn %{insert_post: insert_post} ->
      # Ensure that the slug always contains the id
      Ecto.Changeset.change(insert_post, slug: Post.create_slug(insert_post.title, Post.encode_id(insert_post.id)))
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Publishes a post.

  ## Examples

      iex> publish_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> publish_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def publish_post(org_id, %Post{} = post, attrs) do
    existing = get_post!(org_id, post.id)

    has_atom_keys =
      attrs
      |> Map.keys()
      |> Enum.all?(&is_atom/1)

    attrs =
      if has_atom_keys do
        attrs
      else
        MapExt.atomize_keys(attrs)
      end

    attrs =
      attrs
      |> Map.put(:published_category, attrs[:category] || existing.category)
      |> Map.put(:published_title, attrs[:title] || existing.title)
      |> Map.put(:published_slug, attrs[:slug] || existing.slug)
      |> Map.put(:published_cover, attrs[:cover] || existing.cover)
      |> Map.put(:published_cover_caption, attrs[:cover_caption] || existing.cover_caption)
      |> Map.put(:published_summary, attrs[:summary] || existing.summary)
      |> Map.put(:published_content, attrs[:content] || existing.content)
      |> Map.put(:published_duration, attrs[:duration] || existing.duration)
      |> Map.put(:last_published, DateTime.utc_now())

    post
    |> Post.publish_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Unpublishes a post.

  ## Examples

      iex> unpublish_post(post)
      {:ok, %Post{}}

  """
  def unpublish_post(%Post{} = post) do
    attrs = %{"go_live" => nil}

    post
    |> Post.unpublish_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end
end
