defmodule ExFinanceWeb.CurrencyJSON do
  @moduledoc false
  alias ExFinance.Currencies.Currency

  @doc """
  Renders a list of currencies.
  """
  def index(%{currencies: currencies}) do
    %{data: for(currency <- currencies, do: data(currency))}
  end

  @doc """
  Renders a single currency.
  """
  def show(%{currency: currency}) do
    %{data: data(currency)}
  end

  defp data(%Currency{} = currency) do
    %{
      id: currency.id,
      name: currency.name,
      type: currency.type,
      variation_percent: currency.variation_percent,
      variation_price: currency.variation_price,
      meta: currency.meta,
      info_type: currency.info_type,
      buy_price: currency.buy_price,
      sell_price: currency.sell_price,
      supplier_name: currency.supplier_name,
      supplier_url: currency.supplier_url,
      price_updated_at: currency.price_updated_at
    }
  end
end
