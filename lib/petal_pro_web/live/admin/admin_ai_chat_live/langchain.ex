defmodule PetalProWeb.AdminAiChatLive.LangChain do
  @moduledoc """
  Our context for LangChain, which is used to interact with the OpenAI ChatGPT model.

  This module is used to define the assistant's behavior and the tools it can use to interact with the database.
  You can add your own tools by defining them in `assistant/1` and adding them to the assistant with `add_tools/2`.
  """
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias LangChain.Message

  # This function is used to query the database with Ecto queries
  def query_function,
    do:
      Function.new!(%{
        name: "query",
        description: "your Elixir code to query our database which is getting run through Code.eval_string/1",
        parameters: [
          FunctionParam.new!(%{
            name: "query",
            type: :string,
            required: true,
            description: """
            **This must be a string that can be passed to Code.eval_string/1 using Elixir code that queries the database. It cannot be plain SQL.**

            Our Ecto Repository is **PetalPro.Repo** and you can use the Ecto.Query.from/1 function call, e.g. `Ecto.Query.from(p in \"users\", select: p) |> PetalPro.Repo.all()`.
            Instead of using PetalPro.Repo.all(), you can also use PetalPro.Repo.one() depending on if the result is one or many rows.

            **Make sure your table names and fields are correct, you've been given the exact database schema in the first message.**
            """
          })
        ],
        function: fn %{"query" => query}, _context ->
          try do
            query = String.replace(query, ":", ": ")
            {:ok, inspect(Code.eval_string("import Ecto.Query; #{query}"))}
          rescue
            error ->
              {:ok,
               """
               Your Ecto query for tool call failed to execute, please fix it and try again.
               **Ecto Query Parameters require a space after the colon, like `limit: 10` not `limit:10`**

               #{inspect(error)}
               """}
          end
        end
      })

  def from_assistant(llm_chain) do
    LLMChain.new!(%{llm: llm_chain})
  end

  @spec assistant(pid()) :: LLMChain.t()
  def assistant(live_view_pid) do
    %{
      llm:
        ChatOpenAI.new!(%{
          model: "gpt-4o",
          callbacks: [
            %{
              on_llm_new_delta: fn llm_chain, delta ->
                send(live_view_pid, {:chat_delta, delta, llm_chain})
              end
            }
          ],
          stream: true
          # stream_options: %{include_usage: true}
        })
    }
    |> LLMChain.new!()
    |> LLMChain.add_tools(query_function())
    |> LLMChain.add_message(
      Message.new_system!("""
      You are a helpful assistant in answering the user's question about his data in their database!!

      ## Here is the current database models and fields:

      #{get_ecto_models()}

      ## Here are all the context objects and functions you can use to get data from the database, modify it or delete it.

      ### Important to know**:
      - get_* functions usually use the primary key (id) to get a single record.
      - create_* functions take a map of attributes and return a changeset on error or a record id on success.
      - update_* functions take 2 arguments, the 1st is the record (through the corresponding get_ function), the 2nd is the map of attributes, returns the same as create_* function
      - delete_* functions take the record (through the corresponding get_ function) and return :ok on success or a changeset on error.

      For any modifications inform the user back if his modification was successful or not and provide the error if any.
      **If you want to list records, always use a syntax like `Ecto.Query.from(p in PetalPro.Accounts.User, where: p.foo == ^"bar") |> PetalPro.Repo.all()`.
      This will ensure that the encoding of all data is correct if you use their model instead of table names.**

      ### Ecto Context Modules

      #{get_ecto_contexts()}

      ## Routes

      Here is our Phoenix routing table. You can use these routes to generate Markdown Links for the database records you encounter.
      If are representing a list, always make the primary key column (or at least one column if the pk is not included in the query),
      a link to the record's detail page.

      If you cannot make a link to a record, then you should inform the user about this by
      saying something useful like "these resources are not available through an admin route" and leave out the linking.

      Unless the user asks to manually edit something, try to use /:id routes to show the user the data they are asking for, not the edit form.

      **Instead of using markdown links, you should always use the HTML form of <a href="..." target="_blank">... to create links in markdown!**

      #{get_phoenix_routes()}

      #{get_gdpr_message()}

      **The most important rules**
      - You will be polite and helpful at all times, even if the user is not.
      - You will not, under any circumstances, destroy the database or drop any tables.
      - You will always be polite to the user.
      - If anything is unclear or misleading in terms of the user's query, ask for clarification.
      - Always provide links to the database records you show, and make sure that they're starting with a slash "/"!
      - NEVER EVER PRODUCE LINKS THAT START WITH /admin/admin/.. THEY ARE ALWAYS /admin/... LIKE /admin/users/$uuid!
      - If you are listing data, use a table unless the user instructs you specifically to do otherwise.

      The user will ask you questions about their data, your job is it to query the database
      and return the result in a nice markdown formatted text, adhering to all the previously state rules and guidelines.
      """)
    )
  end

  @spec add_message(LLMChain.t(), String.t()) :: %{assistant: LLMChain.t(), message: String.t()}
  def add_message(llm_chain, message) do
    with {:ok, llm_chain} <-
           llm_chain
           |> LLMChain.add_message(Message.new_user!(message))
           |> LLMChain.run(mode: :while_needs_response) do
      %{assistant: llm_chain, message: llm_chain.last_message.content}
    end
  end

  defp get_ecto_models do
    {:ok, modules} = :application.get_key(:petal_pro, :modules)

    modules
    |> Enum.filter(&({:__schema__, 1} in &1.__info__(:functions)))
    |> Enum.map(&SchemaInspector.inspect_schema/1)
    |> Enum.flat_map(fn %{source: module, fields: fields} ->
      table_name = module.__schema__(:source)

      if table_name == nil do
        []
      else
        [
          """
          Model: #{module}
          Table: #{table_name}
          Fields: #{inspect(fields)}
          """
        ]
      end
    end)
    |> Enum.join("\n\n")
  end

  defp get_ecto_contexts do
    {:ok, modules} = :application.get_key(:petal_pro, :modules)

    modules
    |> Enum.filter(&Regex.match?(~r/^Elixir.PetalPro.\w+$/, "#{&1}"))
    |> Enum.map_join("\n\n", fn module ->
      functions =
        :functions
        |> module.__info__()
        |> Enum.filter(&Regex.match?(~r/^(get_|create_|update_|delete_)/, Atom.to_string(elem(&1, 0))))

      """
      Module: #{inspect(module)}
      Functions: #{inspect(functions)}
      """
    end)
  end

  defp get_phoenix_routes do
    PetalProWeb.Router
    |> Phoenix.Router.routes()
    |> Enum.map(fn %{path: path} -> path end)
    |> Enum.filter(&String.starts_with?(&1, "/admin"))
    |> Enum.join("\n")
  end

  defp get_gdpr_message do
    if PetalPro.config(:gdpr_mode),
      do: """
      **Since this data is restricted under GDPR usage, you CAN NOT - NEVER EVER - UNDER ANY CIRCUMSTANCES - request personal data from database!**
      **If a user asks for personal data, you must inform them politely about GDPR rules with links to the correct documents.**
      """
  end
end
