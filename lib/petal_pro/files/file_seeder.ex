defmodule PetalPro.Files.FileSeeder do
  @moduledoc false
  alias PetalPro.Files

  def create_files(user) do
    analytics_image(user)
    blog_cover_image(user)
    blog_content_image(user)
  end

  def analytics_image(user) do
    attrs = %{
      url: "https://res.cloudinary.com/wickedsites/image/upload/f_auto,h_960/sulzrdaa7cdixgtxwniv",
      name: "Analytics - everybodies favourite activity",
      author_id: user.id
    }

    {:ok, file} = Files.create_file(attrs)

    file
  end

  def blog_cover_image(user) do
    attrs = %{
      url:
        "https://res.cloudinary.com/wickedsites/image/upload/v1733440121/petal_marketing/blog/EDITOR/connor-home-7Qpp39GHY3w-unsplash_1_sia0tp.jpg",
      name: "Become one with the content",
      author_id: user.id
    }

    {:ok, file} = Files.create_file(attrs)

    file
  end

  def blog_content_image(user) do
    attrs = %{
      url:
        "https://res.cloudinary.com/wickedsites/image/upload/v1733447705/petal_marketing/blog/EDITOR/oskars-sylwan-rcAOIMSDfyc-unsplash_1_ckmkqe.jpg",
      name: "Out of nowhere",
      author_id: user.id
    }

    {:ok, file} = Files.create_file(attrs)

    file
  end
end
