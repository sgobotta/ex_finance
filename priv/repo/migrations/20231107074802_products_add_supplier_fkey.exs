defmodule ExFinance.Repo.Migrations.ProductsAddSupplierFkey do
  use Ecto.Migration

  def change do
    alter table(:currencies) do
      add :supplier_id, references(:suppliers, type: :binary_id)
    end
  end
end
