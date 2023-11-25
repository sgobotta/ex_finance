defmodule ExFinance.InstrumentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExFinance.Instruments` context.
  """

  def unique_symbol, do: "symbol-#{System.unique_integer()}"

  def unique_supplier_name, do: "some supplier name #{System.unique_integer()}"

  @doc """
  Generate a cedear.
  """
  def cedear_fixture(attrs \\ %{}) do
    {:ok, cedear} =
      attrs
      |> Enum.into(%{
        country: "some country",
        dividend_payment_frequency: "some dividend_payment_frequency",
        industry: "some industry",
        name: "some name",
        origin_ticker: "some origin_ticker",
        ratio: "120.5",
        supplier_name: unique_supplier_name(),
        symbol: unique_symbol(),
        underlying_market: "some underlying_market",
        underlying_security_value: "some underlying_security_value",
        web_link: "some web_link"
      })
      |> ExFinance.Instruments.create_cedear()

    cedear
  end
end
