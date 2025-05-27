# priv/repo/seeds/modules_seeder.ex
defmodule PetalPro.AppModules.AppModuleSeeder do
  @moduledoc """
  Seeds initial module data into the database.
  """

  import PetalPro.AppModules

  @doc """
  Seeds the predefined modules.
  """
  def seed_modules do
    IO.puts("Seeding modules...")

    seed_app_module(%{
      code: "cms",
      name: "Content Management System",
      description: "Gerencie facilmente o conteúdo do seu site com este sistema completo de gerenciamento de conteúdo.",
      version: "1.0.0",
      dependencies: [],
      status: :active,
      price_id: "price_CMS_Pro",
      is_white_label_ready: true,
      is_publicly_visible: true,
      setup_function: "PetalPro.AppModules.CMS.setup/1",
      cleanup_function: "PetalPro.AppModules.CMS.cleanup/1",
      routes_definition: %{
        main_route: "/cms",
        menu_items: [
          %{label: "Dashboard", path: "/cms/dashboard", icon: "hero-chart-bar"},
          %{label: "Posts", path: "/cms/posts", icon: "hero-document-text"},
          %{label: "Pages", path: "/cms/pages", icon: "hero-document"}
        ]
      }
    })

    seed_app_module(%{
      code: "lms",
      name: "Learning Management System",
      description: "Ofereça cursos online e gerencie o aprendizado de seus usuários com um LMS robusto.",
      version: "1.0.0",
      dependencies: ["cms"],
      status: :active,
      price_id: "price_LMS_Enterprise",
      is_white_label_ready: true,
      is_publicly_visible: true,
      setup_function: "PetalPro.AppModules.LMS.setup/1",
      cleanup_function: "PetalPro.AppModules.LMS.cleanup/1",
      routes_definition: %{
        main_route: "/lms",
        menu_items: [
          %{label: "Courses", path: "/lms/courses", icon: "hero-academic-cap"},
          %{label: "Students", path: "/lms/students", icon: "hero-users"}
        ]
      }
    })

    IO.puts("Modules seeding complete.")
  end

  defp seed_app_module(attrs) do
    case create_app_module(attrs) do
      {:ok, module} ->
        IO.puts("Module created: #{module.name}")

      {:error, %Ecto.Changeset{errors: errors} = changeset} ->
        if Keyword.has_key?(errors, :code) do
          IO.puts("Module with code '#{attrs.code}' already exists. Skipping.")
        else
          IO.puts("Failed to create module with code '#{attrs.code}': #{inspect(changeset.errors)}")
        end
    end
  end
end
