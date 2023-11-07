defmodule ExFinance.Repo do
  use Ecto.Repo,
    otp_app: :ex_finance,
    adapter: Ecto.Adapters.Postgres
end
