defmodule ExFinance.Currencies.Currency do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "currencies" do
    field :buy_price, :decimal
    field :info_type, Ecto.Enum, values: [:reference, :market]
    field :meta, :map, default: %{}
    field :name, :string
    field :price_updated_at, :utc_datetime
    field :sell_price, :decimal
    field :supplier_name, :string
    field :supplier_url, :string
    field :type, :string
    field :variation_percent, :decimal
    field :variation_price, :decimal

    belongs_to :supplier, ExFinance.Currencies.Supplier

    timestamps(type: :utc_datetime)
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
        "price" => sanitize_price(currency["price"]),
        "price_updated_at" => parse_update_time(currency["update_time"])
      })
    )
  end

  @spec sanitize_price(String.t()) :: String.t()
  defp sanitize_price(nil), do: 0

  defp sanitize_price("unpriced"), do: 0

  defp sanitize_price(price), do: price

  defp parse_update_time(update_time) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(update_time <> "Z")

    datetime
  end
end
