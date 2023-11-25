defmodule ExFinance.Instruments.Cedear do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "cedears" do
    field :country, :string
    field :dividend_payment_frequency, :string
    field :industry, :string
    field :meta, :map, default: %{}
    field :name, :string
    field :origin_ticker, :string
    field :ratio, :decimal
    field :supplier_name, :string
    field :symbol, :string
    field :underlying_market, :string
    field :underlying_security_value, :string
    field :web_link, :string

    belongs_to :supplier, ExFinance.Currencies.Supplier

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cedear, attrs) do
    cedear
    |> cast(attrs, [
      :country,
      :dividend_payment_frequency,
      :industry,
      :meta,
      :name,
      :origin_ticker,
      :ratio,
      :supplier_name,
      :symbol,
      :underlying_market,
      :underlying_security_value,
      :web_link
    ])
    |> validate_required([
      :country,
      :dividend_payment_frequency,
      :industry,
      :name,
      :origin_ticker,
      :ratio,
      :supplier_name,
      :symbol,
      :underlying_market,
      :underlying_security_value,
      :web_link
    ])
  end

  def change_supplier(cedear, supplier_id) do
    cedear
    |> cast(%{supplier_id: supplier_id}, [:supplier_id])
    |> validate_required([:supplier_id])
  end

  @spec from_entry!(Redis.Stream.Entry.t()) :: Ecto.Changeset.t()
  def from_entry!(%Redis.Stream.Entry{values: cedear}) do
    changeset(
      %__MODULE__{},
      Map.merge(cedear, %{
        "supplier_name" => cedear["supplier"],
        "meta" => Jason.decode!(cedear["meta"]),
        "underlying_market" => cedear["underlying_market_value"]
      })
    )
  end
end
