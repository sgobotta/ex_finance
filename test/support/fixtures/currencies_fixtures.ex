defmodule ExFinance.CurrenciesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExFinance.Currencies` context.
  """

  @doc """
  Generate a currency.
  """
  def currency_fixture(attrs \\ %{}) do
    {:ok, currency} =
      attrs
      |> Enum.into(%{
        buy_price: "120.5",
        info_type: :reference,
        meta: %{},
        name: "some name",
        price_updated_at: ~N[2023-11-08 04:55:00],
        sell_price: "120.5",
        supplier_name: "some supplier_name",
        supplier_url: "some supplier_url",
        type: "bna",
        variation_percent: "120.5",
        variation_price: "120.5"
      })
      |> ExFinance.Currencies.create_currency()

    currency
  end
end
