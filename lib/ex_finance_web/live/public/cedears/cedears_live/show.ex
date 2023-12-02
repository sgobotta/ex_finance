defmodule ExFinanceWeb.Public.CedearsLive.Show do
  @moduledoc false
  use ExFinanceWeb, :live_view

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency
  alias ExFinance.Instruments
  alias ExFinance.Instruments.{Cedear, CedearPriceCalc}

  @impl true
  def mount(_params, _session, socket) do
    :ok = Currencies.subscribe_currencies()
    ccl_currency = Currencies.get_by_type("ccl")

    cedear_price_calc = %CedearPriceCalc{
      underlying_currency_id: ccl_currency.id
    }

    changeset = Instruments.change_cedear_price_calc(cedear_price_calc)

    {:ok,
     socket
     |> assign_form(changeset)
     |> assign_cedear(nil)
     |> assign_currency(ccl_currency)
     |> assign_cedear_price_calc(cedear_price_calc)
     |> assign_average_stock_price(Decimal.new(0))}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    cedear = Instruments.get_cedear!(id)

    {:noreply,
     socket
     |> assign(:page_title, cedear.name)
     |> assign(:section_title, "Cotización de #{cedear.name}")
     |> assign_cedear(cedear)}
  end

  @impl true
  def handle_info({:currency_updated, %Currency{} = currency}, socket) do
    {:noreply, stream_insert(socket, :currencies, currency, at: -1)}
  end

  @impl true
  def handle_event(
        "change_cedear_price",
        %{"cedear_price_calc" => cedear_price_calc_params},
        socket
      ) do
    changeset =
      socket.assigns.cedear_price_calc
      |> Instruments.change_cedear_price_calc(cedear_price_calc_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_average_stock_price(
       CedearPriceCalc.calculate(socket.assigns.cedear, changeset)
     )
     |> assign_form(changeset)}
  end

  defp assign_cedear(socket, cedear),
    do: assign(socket, :cedear, cedear)

  defp assign_currency(socket, currency),
    do: assign(socket, :currency, currency)

  defp assign_cedear_price_calc(socket, %CedearPriceCalc{} = cedear_price_calc) do
    assign(socket, :cedear_price_calc, cedear_price_calc)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_average_stock_price(socket, average_stock_price) do
    assign(socket, :average_stock_price, average_stock_price)
  end

  defp render_country(%Cedear{country: country}), do: String.upcase(country)

  defp render_ratio(%Cedear{ratio: ratio}), do: "1:#{Decimal.round(ratio)}"

  defp render_underlying_market(%Cedear{underlying_market: underlying_market}),
    do: String.upcase(underlying_market)

  defp get_color_by_price_rate(%Cedear{}), do: "indigo"

  defp render_currency_price(%Currency{variation_price: variation_price}),
    do: "$#{variation_price}"

  defp render_average_stock_price(%Decimal{} = price), do: "$#{price}"
end
