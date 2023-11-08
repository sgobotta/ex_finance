defmodule ExFinance.Repo.Migrations.CreateCurrencies do
  use Ecto.Migration

  def change do
    create table(:currencies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :type, :string
      add :variation_percent, :decimal
      add :variation_price, :decimal
      add :meta, :map
      add :info_type, :string
      add :buy_price, :decimal
      add :sell_price, :decimal
      add :supplier_name, :string
      add :supplier_url, :string
      add :price_updated_at, :naive_datetime

      timestamps()
    end

    create unique_index(:currencies, [:type])
  end
end
