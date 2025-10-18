defmodule ExFinance.Currencies.Converter do
  @moduledoc """
  Provides functions to convert between ARS and USD based on currency prices.
  """
  alias ExFinance.Currencies.Currency

  @spec ars_to_usd(ExFinance.Currencies.Currency.t(), Decimal.t(), any()) ::
          Decimal.t()
  def ars_to_usd(
        %Currency{} = currency,
        %Decimal{} = ars_amount,
        market_price_type
      ) do
    selected_currency_price = get_currency_price(currency, market_price_type)

    Decimal.div(ars_amount, selected_currency_price)
    |> Decimal.round(2)
  end

  @spec usd_to_ars(ExFinance.Currencies.Currency.t(), Decimal.t(), any()) ::
          Decimal.t()
  def usd_to_ars(
        %Currency{} = currency,
        %Decimal{} = usd_amount,
        market_price_type
      ) do
    selected_currency_price = get_currency_price(currency, market_price_type)

    Decimal.mult(usd_amount, selected_currency_price)
    |> Decimal.round(2)
  end

  defp get_currency_price(%Currency{} = currency, market_price_type) do
    case currency.info_type do
      :market -> Map.get(currency, market_price_type)
      :reference -> currency.variation_price
    end
  end
end
