defmodule Mix.Tasks.Petal.Gen.Live do
  @shortdoc "Generates LiveView, templates, and context for a resource using Petal Components"

  @moduledoc """
  This works the same as phx.gen.live but will use Petal Components where possible.

  mix petal.gen.live Blog Post posts title slug:unique votes:integer cost:decimal tags:array:text popular:boolean drafted_at:datetime status:enum:unpublished:published:deleted published_at:utc_datetime published_at_usec:utc_datetime_usec deleted_at:naive_datetime deleted_at_usec:naive_datetime_usec alarm:time alarm_usec:time_usec secret:uuid:redact announcement_date:date weight:float user_id:references:users
  """
  use Mix.Task

  alias Mix.Phoenix.Context
  alias Mix.Phoenix.Schema
  alias Mix.Tasks.Phx.Gen

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phx.gen.live must be invoked from within your *_web application root directory")
    end

    data_table = parse_data_table(args)

    {context, schema} = Gen.Context.build(args)
    Gen.Context.prompt_for_code_injection(context)

    binding = [context: context, schema: schema, inputs: inputs(schema)]
    paths = Mix.Phoenix.generator_paths()

    prompt_for_conflicts(context)

    context
    |> copy_new_files(binding, paths, data_table)
    |> maybe_inject_imports()
    |> print_shell_instructions()
  end

  @doc false
  def parse_data_table(args) do
    {parsed, _, _} = OptionParser.parse(args, switches: [data_table: :boolean])

    parsed[:data_table] || false
  end

  defp prompt_for_conflicts(context) do
    context
    |> files_to_be_generated()
    |> Kernel.++(context_files(context))
    |> Mix.Phoenix.prompt_for_conflicts()
  end

  defp context_files(%Context{generate?: true} = context) do
    Gen.Context.files_to_be_generated(context)
  end

  defp context_files(%Context{generate?: false}) do
    []
  end

  defp files_to_be_generated(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    test_prefix = Mix.Phoenix.web_test_path(context_app)
    web_path = to_string(schema.web_path)
    live_subdir = "#{schema.singular}_live"
    web_live = Path.join([web_prefix, "live", web_path, live_subdir])
    test_live = Path.join([test_prefix, "live", web_path])

    [
      {:eex, "show.ex", Path.join(web_live, "show.ex")},
      {:eex, "index.ex", Path.join(web_live, "index.ex")},
      {:eex, "form_component.ex", Path.join(web_live, "form_component.ex")},
      {:eex, "form_component.html.heex", Path.join(web_live, "form_component.html.heex")},
      {:eex, "index.html.heex", Path.join(web_live, "index.html.heex")},
      {:eex, "show.html.heex", Path.join(web_live, "show.html.heex")},
      {:eex, "live_test.exs", Path.join(test_live, "#{schema.singular}_live_test.exs")}
    ]
  end

  # This is an example of what is available in the templates:
  # [
  #   context: %Mix.Phoenix.Context{
  #     name: "Blog",
  #     module: App.Blog,
  #     schema: %Mix.Phoenix.Schema{
  #       module: App.Blog.Post,
  #       repo: App.Repo,
  #       table: "posts",
  #       collection: "posts",
  #       embedded?: false,
  #       generate?: true,
  #       opts: [schema: true, context: true],
  #       alias: Post,
  #       file: "lib/app/blog/post.ex",
  #       attrs: [
  #         title: :string,
  #         description: :text,
  #         published_at: :naive_datetime,
  #         published: :boolean
  #       ],
  #       string_attr: :description,
  #       plural: "posts",
  #       singular: "post",
  #       uniques: [],
  #       redacts: [],
  #       assocs: [],
  #       types: %{
  #         description: :string,
  #         published: :boolean,
  #         published_at: :naive_datetime,
  #         title: :string
  #       },
  #       indexes: [],
  #       defaults: %{
  #         description: "",
  #         published: ", default: false",
  #         published_at: "",
  #         title: ""
  #       },
  #       human_singular: "Post",
  #       human_plural: "Posts",
  #       binary_id: nil,
  #       migration_defaults: %{
  #         description: "",
  #         published: ", default: false, null: false",
  #         published_at: "",
  #         title: ""
  #       },
  #       migration?: true,
  #       params: %{
  #         create: %{
  #           description: "some description",
  #           published: true,
  #           published_at: ~N[2023-04-03 02:38:00],
  #           title: "some title"
  #         },
  #         default_key: :description,
  #         update: %{
  #           description: "some updated description",
  #           published: false,
  #           published_at: ~N[2023-04-04 02:38:00],
  #           title: "some updated title"
  #         }
  #       },
  #       sample_id: -1,
  #       web_path: nil,
  #       web_namespace: nil,
  #       context_app: :app,
  #       route_helper: "post",
  #       route_prefix: "/posts",
  #       api_route_prefix: "/api/posts",
  #       migration_module: Ecto.Migration,
  #       fixture_unique_functions: %{},
  #       fixture_params: %{
  #         description: "\"some description\"",
  #         published: "true",
  #         published_at: "~N[2023-04-03 02:38:00]",
  #         title: "\"some title\""
  #       },
  #       prefix: nil
  #     },
  #     alias: Blog,
  #     base_module: App,
  #     web_module: AppWeb,
  #     basename: "blog",
  #     file: "lib/app/blog.ex",
  #     test_file: "test/app/blog_test.exs",
  #     test_fixtures_file: "test/support/fixtures/blog_fixtures.ex",
  #     dir: "lib/app/blog",
  #     generate?: true,
  #     context_app: :app,
  #     opts: [schema: true, context: true]
  #   },
  #   schema: %Mix.Phoenix.Schema{
  #     module: App.Blog.Post,
  #     repo: App.Repo,
  #     table: "posts",
  #     collection: "posts",
  #     embedded?: false,
  #     generate?: true,
  #     opts: [schema: true, context: true],
  #     alias: Post,
  #     file: "lib/app/blog/post.ex",
  #     attrs: [
  #       title: :string,
  #       description: :text,
  #       published_at: :naive_datetime,
  #       published: :boolean
  #     ],
  #     string_attr: :description,
  #     plural: "posts",
  #     singular: "post",
  #     uniques: [],
  #     redacts: [],
  #     assocs: [],
  #     types: %{
  #       description: :string,
  #       published: :boolean,
  #       published_at: :naive_datetime,
  #       title: :string
  #     },
  #     indexes: [],
  #     defaults: %{
  #       description: "",
  #       published: ", default: false",
  #       published_at: "",
  #       title: ""
  #     },
  #     human_singular: "Post",
  #     human_plural: "Posts",
  #     binary_id: nil,
  #     migration_defaults: %{
  #       description: "",
  #       published: ", default: false, null: false",
  #       published_at: "",
  #       title: ""
  #     },
  #     migration?: true,
  #     params: %{
  #       create: %{
  #         description: "some description",
  #         published: true,
  #         published_at: ~N[2023-04-03 02:38:00],
  #         title: "some title"
  #       },
  #       default_key: :description,
  #       update: %{
  #         description: "some updated description",
  #         published: false,
  #         published_at: ~N[2023-04-04 02:38:00],
  #         title: "some updated title"
  #       }
  #     },
  #     sample_id: -1,
  #     web_path: nil,
  #     web_namespace: nil,
  #     context_app: :app,
  #     route_helper: "post",
  #     route_prefix: "/posts",
  #     api_route_prefix: "/api/posts",
  #     migration_module: Ecto.Migration,
  #     fixture_unique_functions: %{},
  #     fixture_params: %{
  #       description: "\"some description\"",
  #       published: "true",
  #       published_at: "~N[2023-04-03 02:38:00]",
  #       title: "\"some title\""
  #     },
  #     prefix: nil
  #   },
  #   inputs: ["<.form_field type=\"text_input\" form={f} field={:title} />",
  #    "<.form_field type=\"textarea\" form={f} field={:description} />",
  #    "<.form_field type=\"datetime_select\" form={f} field={:published_at} />",
  #    "<.form_field type=\"checkbox\" form={f} field={:published} />"],
  #   assigns: %{gettext: true, web_namespace: "AppWeb"}
  # ]
  defp copy_new_files(%Context{} = context, binding, paths, data_table) do
    files = files_to_be_generated(context)

    binding =
      Keyword.put(binding, :assigns, %{
        web_namespace: inspect(context.web_module),
        gettext: true
      })

    source =
      if data_table do
        "priv/templates/mix/petal.gen.live.data_table"
      else
        "priv/templates/mix/petal.gen.live"
      end

    Mix.Phoenix.copy_from(paths, source, binding, files)
    if context.generate?, do: Gen.Context.copy_new_files(context, paths, binding)

    context
  end

  defp maybe_inject_imports(%Context{context_app: ctx_app} = context) do
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    [lib_prefix, web_dir] = Path.split(web_prefix)
    file_path = Path.join(lib_prefix, "#{web_dir}.ex")
    file = File.read!(file_path)
    inject = "import #{inspect(context.web_module)}.CoreComponents"

    if String.contains?(file, inject) do
      :ok
    else
      do_inject_imports(context, file, file_path, inject)
    end

    context
  end

  defp do_inject_imports(context, file, file_path, inject) do
    relative_path = Path.relative_to_cwd(file_path)
    Mix.shell().info([:green, "* injecting ", :reset, relative_path])

    new_file =
      String.replace(
        file,
        "use Phoenix.Component",
        "use Phoenix.Component\n      #{inject}"
      )

    if file != new_file do
      File.write!(file_path, new_file)
    else
      Mix.shell().info("""

      Could not find use Phoenix.Component in #{file_path}.

      This typically happens because your application was not generated
      with the --live flag:

          mix phx.new my_app --live

      Please make sure LiveView is installed and that #{inspect(context.web_module)}
      defines both `live_view/0` and `live_component/0` functions,
      and that both functions import #{inspect(context.web_module)}.CoreComponents.
      """)
    end
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: ctx_app} = context) do
    prefix = Module.concat(context.web_module, schema.web_namespace)
    web_path = Mix.Phoenix.web_path(ctx_app)

    if schema.web_namespace do
      Mix.shell().info("""

      Add the live routes to your #{schema.web_namespace} :browser scope in #{web_path}/router.ex:

          scope "/#{schema.web_path}", #{inspect(prefix)}, as: :#{schema.web_path} do
            pipe_through :browser
            ...

      #{for line <- live_route_instructions(schema), do: "      #{line}"}
          end
      """)
    else
      Mix.shell().info("""

      Add the live routes to your browser scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

      #{for line <- live_route_instructions(schema), do: "    #{line}"}
      """)
    end

    if context.generate?, do: Gen.Context.print_shell_instructions(context)
    maybe_print_upgrade_info()
  end

  defp maybe_print_upgrade_info do
    unless Code.ensure_loaded?(Phoenix.LiveView.JS) do
      Mix.shell().info("""

      You must update :phoenix_live_view to v0.18 or later and
      :phoenix_live_dashboard to v0.7 or later to use the features
      in this generator.
      """)
    end
  end

  defp live_route_instructions(schema) do
    [
      ~s|live "/#{schema.plural}", #{inspect(schema.alias)}Live.Index, :index\n|,
      ~s|live "/#{schema.plural}/new", #{inspect(schema.alias)}Live.Index, :new\n|,
      ~s|live "/#{schema.plural}/:id/edit", #{inspect(schema.alias)}Live.Index, :edit\n\n|,
      ~s|live "/#{schema.plural}/:id", #{inspect(schema.alias)}Live.Show, :show\n|,
      ~s|live "/#{schema.plural}/:id/show/edit", #{inspect(schema.alias)}Live.Show, :edit|
    ]
  end

  @doc false
  def inputs(%Schema{} = schema) do
    Enum.map(schema.attrs, fn
      {_, {:references, _}} ->
        ""

      {key, :integer} ->
        ~s(<.field type="number" field={@form[#{inspect(key)}]} />)

      {key, :float} ->
        ~s(<.field type="number" field={@form[#{inspect(key)}]} />)

      {key, :decimal} ->
        ~s(<.field type="number" field={@form[#{inspect(key)}]} />)

      {key, :boolean} ->
        ~s(<.field type="checkbox" field={@form[#{inspect(key)}]} />)

      {key, :text} ->
        ~s(<.field type="textarea" field={@form[#{inspect(key)}]} />)

      {key, :date} ->
        ~s(<.field type="date" field={@form[#{inspect(key)}]} />)

      {key, :time} ->
        ~s(<.field type="time" field={@form[#{inspect(key)}]} />)

      {key, :time_usec} ->
        ~s(<.field type="time" field={@form[#{inspect(key)}]} />)

      {key, :utc_datetime} ->
        ~s(<.field type="datetime-local" field={@form[#{inspect(key)}]} />)

      {key, :utc_datetime_usec} ->
        ~s(<.field type="datetime-local" field={@form[#{inspect(key)}]} />)

      {key, :naive_datetime} ->
        ~s(<.field type="datetime-local" field={@form[#{inspect(key)}]} />)

      {key, :naive_datetime_usec} ->
        ~s(<.field type="datetime-local" field={@form[#{inspect(key)}]} />)

      {key, {:array, :integer}} ->
        ~s(<.field type="checkbox-group" field={@form[#{inspect(key)}]} options={["Option 1": 1, "Option 2": 2, "Option 3": 3]} />)

      {key, {:array, :string}} ->
        ~s(<.combo_box multiple field={@form[#{inspect(key)}]} options={["Option 1": "option1", "Option 2": "option2", "Option 3": "option3"]} />)

      {key, {:array, _}} ->
        ~s(<.field type="checkbox-group" field={@form[#{inspect(key)}]} options={["Option 1": "option1", "Option 2": "option2", "Option 3": "option3"]} />)

      {key, {:enum, _}} ->
        ~s|<.field type="select" field={@form[#{inspect(key)}]} options={Ecto.Enum.values(#{inspect(schema.module)}, #{inspect(key)})} prompt="Choose a value" />|

      {key, _} ->
        ~s(<.field type="text" field={@form[#{inspect(key)}]} />)
    end)
  end
end
