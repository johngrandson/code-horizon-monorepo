defmodule FixtureHelpers do
  @moduledoc false
  def in_vcr?(name) do
    [
      Application.fetch_env!(:exvcr, :vcr_cassette_library_dir),
      ExVCR.Mock.normalize_fixture(name) <> ".json"
    ]
    |> Path.join()
    |> File.exists?()
  end
end
