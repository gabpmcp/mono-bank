defmodule MonoApp.Repo do
  use Ecto.Repo,
    otp_app: :mono_app,
    adapter: Ecto.Adapters.Postgres
end
