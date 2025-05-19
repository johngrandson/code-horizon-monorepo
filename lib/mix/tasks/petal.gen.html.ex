defmodule Mix.Tasks.Petal.Gen.Html do
  @shortdoc "Generates context and controller for an HTML resource"

  @moduledoc """
  Works the same as petal.gen.html but uses Petal Components

      mix petal.gen.html Accounts User users name:string age:integer

  To test with all data types:

      mix petal.gen.html Blog Post posts title slug:unique votes:integer cost:decimal tags:array:text popular:boolean drafted_at:datetime status:enum:unpublished:published:deleted published_at:utc_datetime published_at_usec:utc_datetime_usec deleted_at:naive_datetime deleted_at_usec:naive_datetime_usec alarm:time alarm_usec:time_usec secret:uuid:redact announcement_date:date weight:float user_id:references:users
  """
  use Mix.Task

  alias Mix.Phoenix.Context
  alias Mix.Phoenix.Schema
  alias Mix.Tasks.Phx.Gen

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix petal.gen.html must be invoked from within your *_web application root directory")
    end

    {context, schema} = Gen.Context.build(args)
    Gen.Context.prompt_for_code_injection(context)

    binding = [context: context, schema: schema, inputs: inputs(schema)]
    paths = Mix.Phoenix.generator_paths()

    prompt_for_conflicts(context)

    context
    |> copy_new_files(paths, binding)
    |> print_shell_instructions()
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

  @doc false
  def files_to_be_generated(%Context{schema: schema, context_app: context_app}) do
    singular = schema.singular
    web_prefix = Mix.Phoenix.web_path(context_app)
    test_prefix = Mix.Phoenix.web_test_path(context_app)
    web_path = to_string(schema.web_path)
    controller_pre = Path.join([web_prefix, "controllers", web_path])
    test_pre = Path.join([test_prefix, "controllers", web_path])

    [
      {:eex, "controller.ex", Path.join([controller_pre, "#{singular}_controller.ex"])},
      {:eex, "edit.html.heex", Path.join([controller_pre, "#{singular}_html", "edit.html.heex"])},
      {:eex, "index.html.heex", Path.join([controller_pre, "#{singular}_html", "index.html.heex"])},
      {:eex, "_form.html.heex", Path.join([controller_pre, "#{singular}_html", "_form.html.heex"])},
      {:eex, "new.html.heex", Path.join([controller_pre, "#{singular}_html", "new.html.heex"])},
      {:eex, "show.html.heex", Path.join([controller_pre, "#{singular}_html", "show.html.heex"])},
      {:eex, "html.ex", Path.join([controller_pre, "#{singular}_html.ex"])},
      {:eex, "controller_test.exs", Path.join([test_pre, "#{singular}_controller_test.exs"])}
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from(paths, "priv/templates/mix/petal.gen.html", binding, files)
    if context.generate?, do: Gen.Context.copy_new_files(context, paths, binding)
    context
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: ctx_app} = context) do
    if schema.web_namespace do
      Mix.shell().info("""

      Add the resource to your #{schema.web_namespace} :browser scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

          scope "/#{schema.web_path}", #{inspect(Module.concat(context.web_module, schema.web_namespace))}, as: :#{schema.web_path} do
            pipe_through :browser
            ...
            resources "/#{schema.plural}", #{inspect(schema.alias)}Controller
          end
      """)
    else
      Mix.shell().info("""

      Add the resource to your browser scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

          resources "/#{schema.plural}", #{inspect(schema.alias)}Controller
      """)
    end

    if context.generate?, do: Gen.Context.print_shell_instructions(context)
  end

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
        ~s(<.field type="checkbox-group" field={@form[#{inspect(key)}]} options={["Option 1": "option1", "Option 2": "option2"]} />)

      {key, {:enum, _}} ->
        ~s|<.field type="select" field={@form[#{inspect(key)}]} options={Ecto.Enum.values(#{inspect(schema.module)}, #{inspect(key)})} prompt="Choose a value" />|

      {key, _} ->
        ~s(<.field type="text" field={@form[#{inspect(key)}]} />)
    end)
  end

  @doc false
  def indent_inputs(inputs, column_padding) do
    columns = String.duplicate(" ", column_padding)

    inputs
    |> Enum.map(fn input ->
      lines = input |> String.split("\n") |> Enum.reject(&(&1 == ""))

      case lines do
        [line] ->
          [columns, line]

        [first_line | rest] ->
          rest = Enum.map_join(rest, "\n", &(columns <> &1))
          [columns, first_line, "\n", rest]
      end
    end)
    |> Enum.intersperse("\n")
  end
end
