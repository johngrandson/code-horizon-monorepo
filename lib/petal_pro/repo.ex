defmodule PetalPro.Repo do
  use Ecto.Repo,
    otp_app: :petal_pro,
    adapter: Ecto.Adapters.Postgres

  use PetalPro.Extensions.Ecto.RepoExt
end
