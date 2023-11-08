defmodule ExFinance.Currencies.Currency do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "currencies" do
    field :name, :string
    field :type, :string
    field :variation_percent, :decimal
    field :variation_price, :decimal
    field :meta, :map, default: %{}
    field :info_type, Ecto.Enum, values: [:reference, :market]
    field :buy_price, :decimal
    field :sell_price, :decimal
    field :supplier_name, :string
    field :supplier_url, :string
    field :price_updated_at, :naive_datetime

    belongs_to :supplier, ExFinance.Currencies.Supplier

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :name,
      :type,
      :variation_percent,
      :variation_price,
      :meta,
      :info_type,
      :buy_price,
      :sell_price,
      :supplier_name,
      :supplier_url,
      :price_updated_at
    ])
    |> validate_required([
      :name,
      :type,
      :variation_percent,
      :info_type
    ])
    |> unique_constraint(:type)
  end

  def change_supplier(currency, supplier_id) do
    currency
    |> cast(%{supplier_id: supplier_id}, [:supplier_id])
    |> validate_required([:supplier_id])
  end

  @spec from_entry!(Redis.Stream.Entry.t()) :: Ecto.Changeset.t()
  def from_entry!(%Redis.Stream.Entry{values: currency}) do
    changeset(
      %__MODULE__{},
      Map.merge(currency, %{
        "supplier_name" => currency["supplier"],
        "meta" => Jason.decode!(currency["meta"]),
        "price" => sanitize_price(currency["price"])
      })
    )
  end

  @spec sanitize_price(String.t()) :: String.t()
  defp sanitize_price(nil), do: 0

  defp sanitize_price("unpriced"), do: 0

  defp sanitize_price(price), do: price
end
