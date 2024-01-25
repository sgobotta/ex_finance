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

defmodule ExFinance.Instruments.CedearPriceCalc do
  @moduledoc """
  Struct to calculate a cedear price based on the price value of a CCL currency.
  """
  alias ExFinance.Currencies.Currency
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  embedded_schema do
    field :cedear_price, :decimal, default: Decimal.new(0)
    field :stock_price, :decimal, default: nil

    belongs_to :underlying_currency, ExFinance.Currencies.Currency,
      type: :binary_id
  end

  @doc false
  def changeset(cedear, attrs) do
    cedear
    |> ExFinance.Repo.preload(:underlying_currency)
    |> cast(attrs, [
      :cedear_price,
      :stock_price,
      :underlying_currency_id
    ])
    |> cast_assoc(:underlying_currency)
    |> validate_required([
      :cedear_price
    ])
  end

  def calculate_stock_price(%ExFinance.Instruments.Cedear{}, %Ecto.Changeset{
        valid?: false
      }) do
    Decimal.new(0)
  end

  def calculate_stock_price(
        %ExFinance.Instruments.Cedear{ratio: ratio},
        %Ecto.Changeset{valid?: true} = cs
      ) do
    %ExFinance.Currencies.Currency{
      variation_price: variation_price
    } = get_field(cs, :underlying_currency)

    cedear_price = get_field(cs, :cedear_price)

    Decimal.mult(cedear_price, ratio)
    |> Decimal.div(variation_price)
    |> Decimal.round(2)
  end

  @doc """
  Given a stock price, a cedear and the underlying cedear currency, returns the
  fair price for the given cedear, according to the cedear ratio and the current
  currency value.
  """
  @spec calculate_cedear_price(
          ExFinnhub.StockPrice.t(),
          ExFinance.Instruments.Cedear.t(),
          Currency.t()
        ) :: Decimal.t()
  def calculate_cedear_price(
        %ExFinnhub.StockPrice{current: current_price},
        %ExFinance.Instruments.Cedear{ratio: ratio},
        %Currency{variation_price: variation_price}
      ) do
    Decimal.mult(Decimal.new(current_price), variation_price)
    |> Decimal.div(ratio)
    |> Decimal.round(2)
  end
end
