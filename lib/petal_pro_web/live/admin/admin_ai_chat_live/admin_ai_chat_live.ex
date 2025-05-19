defmodule PetalProWeb.AdminAiChatLive do
  @moduledoc """
  The interactive admin live view.

  Allows admins to interact with the database using OpenAI's ChatGPT.
  Do not expose to ordinary users! Huge security risks!

  **To modify this live view to handle your own custom functions, take a look at `langchain.ex` in this folder**

  **In case you need some more rules for the Chatbot to adhere to, just expand on the Markdown in the `PetalProWeb.AdminAiChatLive.LangChain.assistant/1` function.**
  """
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent

  alias PetalProWeb.AdminAiChatLive.LangChain
  alias PetalProWeb.AdminAiChatLive.Message
  alias PetalProWeb.LangChainHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: gettext("Admin AI Chat"),
       loading: false,
       form: to_form(Message.changeset()),
       messages: [
         %{
           role: :assistant,
           content: """
           Hey there! I'm the Admin AI ChatGPT. I'm here to help you with any questions you have about your Petal Pro Project's Database.

           For example, try asking me how many paying subscribers your project got in the past 14 days.

           _Tip: You can also press and hold the microphone button to speak with me_
           """
         }
       ],
       assistant: LangChain.assistant(self())
     )
     |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)}
  end

  defp handle_progress(:audio, entry, socket) when entry.done? do
    transcription =
      consume_uploaded_entry(socket, entry, fn %{path: path} ->
        LangChainHelpers.openai_wav_transcription(path, model: "whisper-1", language: "EN", response_format: "text")
      end)

    {:noreply,
     socket
     |> assign(form: to_form(Message.changeset(%Message{}, %{content: transcription})))
     |> push_event("focus", %{selector: "#chat-message"})}
  end

  defp handle_progress(_name, _entry, socket), do: {:noreply, socket}

  @impl true
  def handle_event("validate", %{"message" => message}, socket) do
    changeset = Message.changeset(%Message{}, message)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("submit", %{"message" => %{"content" => message}}, socket) do
    # prevent copying the entire socket into the start_async/3
    assistant = socket.assigns.assistant

    messages =
      socket.assigns.messages ++
        [
          %{
            role: :user,
            content: message
          }
        ]

    {:noreply,
     socket
     |> assign(
       response: "",
       loading: true,
       messages: messages,
       form: to_form(Message.changeset(%Message{}, %{content: ""}))
     )
     |> start_async(:assistant, fn -> LangChain.add_message(assistant, message) end)}
  end

  @impl true
  def handle_info(:retry_gpt, socket) do
    assistant = socket.assigns.assistant

    message =
      socket.assigns.messages
      |> Enum.filter(&(&1.role == :user))
      |> List.last()
      |> Map.get(:content)

    {:noreply, start_async(socket, :assistant, fn -> LangChain.add_message(assistant, message) end)}
  end

  @impl true
  def handle_info({:chat_delta, %Elixir.LangChain.MessageDelta{content: delta}, _assistant}, socket) do
    if delta == nil,
      do: {:noreply, socket},
      else: {:noreply, assign(socket, response: "#{socket.assigns.response}#{delta}")}
  end

  @impl true
  def handle_async(:assistant, {:ok, %{assistant: assistant, message: message}}, socket) do
    messages =
      socket.assigns.messages ++
        [
          %{
            role: :assistant,
            content: message
          }
        ]

    {:noreply,
     socket
     |> assign(messages: messages, response: nil, assistant: assistant, loading: false)
     |> push_event("focus", %{selector: "#chat-message"})}
  end

  def handle_async(:assistant, {:ok, {:error, _}}, socket) do
    {:noreply,
     socket
     |> assign(response: "An error occurred while processing your request. Please try again.", loading: false)
     |> push_event("focus", %{selector: "#chat-message"})}
  end

  @timeout_regex ~r/Please try again in (?<timeout>\d+\.\d+)(?<unit>s|ms|m)\./
  def handle_async(:assistant, {:ok, {:error, _, e2}}, socket) do
    messages =
      case Regex.named_captures(@timeout_regex, e2) do
        %{"timeout" => timeout, "unit" => unit} ->
          Process.send_after(self(), :retry_gpt, timeout_to_seconds(timeout, unit))

          socket.assigns.messages ++
            [
              %{
                role: :assistant,
                content: """
                *Received rate limit from OpenAI, we're waiting for the exact time (#{timeout}#{unit}) to continue.*

                To find out more about their rate limiting policy, please visit their documentation at https://platform.openai.com/accounts/rate-limits.
                """
              }
            ]

        _other ->
          socket.assigns.messages ++
            [
              %{
                role: :assistant,
                content: e2
              }
            ]
      end

    {:noreply,
     socket
     |> assign(
       response: "An error occurred while processing your request. Please try again.",
       loading: false,
       messages: messages
     )
     |> push_event("focus", %{selector: "#chat-message"})}
  end

  defp timeout_to_seconds(timeout, "m"), do: round(String.to_float(timeout) * 60 * 1000)
  defp timeout_to_seconds(timeout, "s"), do: round(String.to_float(timeout) * 1000)
  defp timeout_to_seconds(timeout, "ms"), do: timeout |> String.to_float() |> round()

  attr :content, :string, required: true, doc: "The content to render as markdown."
  attr :class, :string, doc: "The class to apply to the rendered markdown.", default: ""

  defp unsafe_markdown(assigns) do
    ~H"""
    <div class={[
      "prose dark:prose-invert prose-img:rounded-xl prose-img:mx-auto prose-a:text-primary-600 prose-a:dark:text-primary-300",
      @class
    ]}>
      {raw(
        PetalPro.MarkdownRenderer.to_html(@content, %Earmark.Options{
          code_class_prefix: "language-",
          escape: false
        })
      )}
    </div>
    """
  end

  defp submit_button_class(false), do: "dark:bg-gray-700 bg-white"

  defp submit_button_class(true),
    do:
      "bg-primary-500 dark:text-gray-900 -rotate-90 ring-primary-500 hover:ring-primary-600 hover:bg-primary-600 focus:bg-primary-600 dark:bg-gray-300 dark:hover-bg-gray-400 dark:ring-gray-300 dark:hover:ring-gray-400 dark:focus:ring-gray-600"

  defp submit_icon_class(false), do: ""
  defp submit_icon_class(true), do: "text-white dark:text-gray-900"
end
