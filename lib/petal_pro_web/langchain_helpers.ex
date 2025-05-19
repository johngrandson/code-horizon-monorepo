defmodule PetalProWeb.LangChainHelpers do
  @moduledoc false
  alias HTTPoison.Response

  @openai_transcription_url "https://api.openai.com/v1/audio/transcriptions"

  defp get_authorization_headers do
    openai_api_key = Application.get_env(:langchain, :openai_key)
    openai_org_id = Application.get_env(:langchain, :openai_org_id)
    openai_proj_id = Application.get_env(:langchain, :openai_proj_id)

    headers = [
      {"Authorization", "Bearer #{openai_api_key}"},
      {"Openai-Organization", openai_org_id}
    ]

    if openai_proj_id in [nil, ""],
      do: headers,
      else:
        headers ++
          [
            {"Openai-Project", openai_proj_id}
          ]
  end

  @doc """
  This function illustrates how one can do plain OpenAI requests relatively simple to do things
  like transcription with whisper, which langchain does not provide us.
  """
  def openai_wav_transcription(file_path, params \\ []) do
    body_params = Enum.map(params, fn {k, v} -> {Atom.to_string(k), v} end)

    body = {
      :multipart,
      [
        {:file, file_path, {"form-data", [{:name, "file"}, {:filename, Path.basename(file_path) <> ".wav"}]}, []}
      ] ++ body_params
    }

    case HTTPoison.post(@openai_transcription_url, body, get_authorization_headers()) do
      {:ok, %Response{status_code: 200, body: {:ok, body}}} ->
        res =
          Map.new(body, fn {k, v} -> {String.to_atom(k), v} end)

        {:ok, res}

      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %Response{body: {:ok, body}}} ->
        {:error, body}

      {:ok, %Response{body: {:error, body}}} ->
        {:error, body}

      # html error responses
      {:ok, %Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
