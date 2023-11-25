defmodule ExFinance.Repo.Migrations.CreateCedears do
  use Ecto.Migration

  def change do
    create table(:cedears, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :dividend_payment_frequency, :string
      add :country, :string
      add :industry, :string
      add :meta, :map
      add :name, :string
      add :origin_ticker, :string
      add :ratio, :decimal
      add :supplier_name, :string
      add :symbol, :string
      add :underlying_market, :string
      add :underlying_security_value, :string
      add :web_link, :string

      add :supplier_id, references(:suppliers, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cedears, [:symbol, :underlying_market])
  end
end
