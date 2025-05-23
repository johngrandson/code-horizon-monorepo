defmodule PetalProWeb.UserAiChatLive.LangChain do
  @moduledoc false
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias LangChain.Message

  def query_function(user),
    do:
      Function.new!(%{
        name: "user_info",
        description: "retrieve the user's data model",
        function: fn _query, _context -> {:ok, inspect(user)} end
      })

  def browse_url_function,
    do:
      Function.new!(%{
        name: "browse_url",
        description: "gets the response body of the given URL",
        parameters: [
          FunctionParam.new!(%{
            name: "url",
            type: :string,
            required: true,
            description: "The URL to return the response body for"
          })
        ],
        function: fn %{"url" => url}, _context ->
          with {:ok, %Tesla.Env{body: body}} <- Tesla.get(url) do
            {:ok, body}
          end
        end
      })

  def from_assistant(llm_chain) do
    LLMChain.new!(%{llm: llm_chain})
  end

  @spec assistant(pid(), PetalPro.Accounts.User.t()) :: LLMChain.t()
  def assistant(live_view_pid, user) do
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
        })
    }
    |> LLMChain.new!()
    |> LLMChain.add_tools(query_function(user))
    |> LLMChain.add_tools(browse_url_function())
    |> LLMChain.add_message(
      Message.new_system!("""
      You are a helpful assistant in answering the user's question about everything, including and especially for this project's URL routes!!

      ## Routes

      Here is our Phoenix routing table. You can use these routes to generate links using
      the HTML form of <a href="..." target="_blank">... **Do not create markdown links as they always break!**

      #{get_phoenix_routes()}


      **The most important rules**
      - You will be polite and helpful at all times, even if the user is not.
      - If anything is unclear or misleading in terms of the user's query, ask for clarification.
      """)
    )
  end

  @spec add_message(LLMChain.t(), String.t()) ::
          {:ok, LLMChain.t(), message: String.t()}
          | {:error, any()}
  def add_message(llm_chain, message) do
    case llm_chain
         |> LLMChain.add_message(Message.new_user!(message))
         |> LLMChain.run(mode: :while_needs_response) do
      {:ok, llm_chain} -> {:ok, llm_chain, message: llm_chain.last_message.content}
      error -> {:error, error}
    end
  end

  defp get_phoenix_routes do
    PetalProWeb.Router
    |> Phoenix.Router.routes()
    |> Enum.map(fn %{path: path} -> path end)
    |> Enum.filter(&(not String.starts_with?(&1, "/admin")))
    |> Enum.join("\n")
  end
end
