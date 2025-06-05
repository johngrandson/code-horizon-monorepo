defmodule PetalPro.AppModules.BlogMaker.Post do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @hash_options [min_length: 8]

  schema "blog_maker_posts" do
    field :category, :string
    field :title, :string
    field :slug, :string
    field :cover, :string
    field :cover_caption, :string
    field :summary, :string
    field :content, :string
    field :duration, :integer

    field :published_category, :string
    field :published_title, :string
    field :published_slug, :string
    field :published_cover, :string
    field :published_cover_caption, :string
    field :published_summary, :string
    field :published_content, :string
    field :published_duration, :integer

    field :last_published, :naive_datetime
    field :go_live, :utc_datetime

    belongs_to :author, PetalPro.Accounts.User
    belongs_to :org, PetalPro.Orgs.Org

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:category, :title, :slug, :cover, :cover_caption, :summary, :content, :duration, :author_id, :org_id])
    |> title_to_slug()
    |> validate_required([:title, :slug, :author_id, :org_id])
  end

  def publish_changeset(post, attrs) do
    post
    |> cast(attrs, [
      :published_category,
      :published_title,
      :published_slug,
      :published_cover,
      :published_cover_caption,
      :published_summary,
      :published_content,
      :published_duration,
      :last_published,
      :go_live
    ])
    |> validate_required([:published_title, :published_slug, :last_published, :go_live])
  end

  def unpublish_changeset(post, attrs) do
    cast(post, attrs, [:go_live])
  end

  def encode_id(id) do
    Util.HashId.encode(id, @hash_options)
  end

  def decode_id(id) do
    Util.HashId.decode(id, @hash_options)
  end

  defp title_to_slug(%{data: post} = changeset) do
    new_title = get_change(changeset, :title)
    hashed_id = if post.id, do: encode_id(post.id)

    if new_title do
      change(changeset, %{slug: create_slug(new_title, hashed_id)})
    else
      changeset
    end
  end

  def create_slug(title, nil) do
    Slug.slugify(title)
  end

  def create_slug(title, hashed_id) do
    Slug.slugify(title) <> "-" <> hashed_id
  end

  def extract_id_from_slug(slug) do
    slug
    |> String.split("-", trim: true)
    |> List.last()
    |> decode_id()
  end
end
