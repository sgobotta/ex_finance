defmodule ExFinanceWeb.Public.CedearsLive.Show do
  @moduledoc false
  use ExFinanceWeb, :live_view

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency
  alias ExFinance.Instruments
  alias ExFinance.Instruments.{Cedear, CedearPriceCalc}

  @fetch_interval :timer.seconds(60)

  @impl true
  def mount(_params, _session, socket) do
    :ok = Currencies.subscribe_currencies()
    ccl_currency = Currencies.get_by_type("ccl")

    cedear_price_calc = %CedearPriceCalc{
      underlying_currency_id: ccl_currency.id
    }

    changeset = Instruments.change_cedear_price_calc(cedear_price_calc)

    send_stock_price_fetching()

    {:ok,
     socket
     |> assign_changeset(changeset)
     |> assign_form(changeset)
     |> assign_cedear(nil)
     |> assign_currency(ccl_currency)
     |> assign_cedear_price_calc(cedear_price_calc)
     |> assign_stock_price(nil)
     |> assign_average_stock_price(Decimal.new(0))
     |> assign_stock_price_changes()}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    cedear = Instruments.get_cedear!(id)

    {:noreply,
     socket
     |> assign(:page_title, cedear.name)
     |> assign(:section_title, gettext("%{cedear} price", cedear: cedear.name))
     |> assign_cedear(cedear)}
  end

  @impl true
  def handle_info(
        {:currency_updated, %Currency{type: "ccl"} = currency},
        socket
      ),
      do: {:noreply, assign(socket, :currency, currency)}

  @impl true
  def handle_info({:currency_updated, %Currency{}}, socket),
    do: {:noreply, socket}

  @impl true
  def handle_info(:stock_price_fetching, socket) do
    stock_price = fetch_stock_price_by_cedear(socket.assigns.cedear)

    schedule_stock_price_fetching()

    stock_price_changes =
      CedearPriceCalc.calculate_stock_price_changes(
        socket.assigns.cedear,
        socket.assigns.changeset,
        stock_price
      )

    {:noreply,
     socket
     |> assign_stock_price(stock_price)
     |> assign_stock_price_changes(stock_price_changes)}
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

    %Decimal{} =
      average_stock_price =
      CedearPriceCalc.calculate_stock_price(socket.assigns.cedear, changeset)

    stock_price_changes =
      CedearPriceCalc.calculate_stock_price_changes(
        socket.assigns.cedear,
        changeset,
        socket.assigns.stock_price
      )

    {:noreply,
     socket
     |> assign_average_stock_price(average_stock_price)
     |> assign_stock_price_changes(stock_price_changes)
     |> assign_changeset(changeset)
     |> assign_form(changeset)}
  end

  defp send_stock_price_fetching,
    do: send(self(), :stock_price_fetching)

  defp fetch_stock_price_by_cedear(%Cedear{} = cedear),
    do: Instruments.fetch_stock_price_by_cedear(cedear)

  defp schedule_stock_price_fetching,
    do: Process.send_after(self(), :stock_price_fetching, @fetch_interval)

  defp assign_cedear(socket, cedear),
    do: assign(socket, :cedear, cedear)

  defp assign_currency(socket, currency),
    do: assign(socket, :currency, currency)

  defp assign_cedear_price_calc(socket, %CedearPriceCalc{} = cedear_price_calc),
    do: assign(socket, :cedear_price_calc, cedear_price_calc)

  defp assign_changeset(socket, %Ecto.Changeset{} = changeset),
    do: assign(socket, :changeset, changeset)

  defp assign_form(socket, %Ecto.Changeset{} = changeset),
    do: assign(socket, :form, to_form(changeset))

  defp assign_stock_price(socket, stock_price),
    do: assign(socket, :stock_price, stock_price)

  defp assign_average_stock_price(socket, average_stock_price),
    do: assign(socket, :average_stock_price, average_stock_price)

  defp assign_stock_price_changes(socket),
    do:
      assign(socket, :stock_price_changes, %{
        stock_price: Decimal.new(0),
        fair_cedear_price: Decimal.new(0),
        fair_stock_price: Decimal.new(0),
        change_percentage: Decimal.new(0),
        change_price: Decimal.new(0)
      })

  defp assign_stock_price_changes(socket, stock_price_changes),
    do: assign(socket, :stock_price_changes, stock_price_changes)

  defp render_country(%Cedear{country: country}), do: String.upcase(country)

  defp render_ratio(%Cedear{ratio: ratio}), do: "1:#{Decimal.round(ratio)}"

  defp render_underlying_market(%Cedear{underlying_market: underlying_market}),
    do: String.upcase(underlying_market)

  defp render_currency_price(%Currency{variation_price: variation_price}),
    do: "$#{variation_price}"

  defp render_stock_change_percentage(%{change_percentage: %Decimal{coef: 0}}),
    do: "0%"

  defp render_stock_change_percentage(%{
         change_percentage: %Decimal{sign: 1} = change_percentage
       }),
       do: "+#{change_percentage}%"

  defp render_stock_change_percentage(%{
         change_percentage: %Decimal{sign: -1} = change_percentage
       }),
       do: "#{change_percentage}%"

  defp render_stock_change_price(%{
         change_price: %Decimal{coef: 0} = change_price
       }),
       do: "#{change_price}"

  defp render_stock_change_price(%{
         change_price: %Decimal{sign: 1} = change_price
       }),
       do: "+#{change_price}"

  defp render_stock_change_price(%{
         change_price: %Decimal{sign: -1} = change_price
       }),
       do: "#{change_price}"

  defp render_stock_price(%{stock_price: %Decimal{} = stock_price}),
    do: "#{stock_price}"

  def render_fair_cedear_price(
        %{fair_cedear_price: %Decimal{} = fair_cedear_price} = changes
      ) do
    "#{fair_cedear_price}"
  end

  defp get_color_by_percentage_change(%{change_percentage: %Decimal{coef: 0}}),
    do: "gray"

  defp get_color_by_percentage_change(%{change_percentage: %Decimal{sign: 1}}),
    do: "green"

  defp get_color_by_percentage_change(%{change_percentage: %Decimal{sign: -1}}),
    do: "red"

  defp get_color_by_price_change(%{change_price: %Decimal{coef: 0}}), do: "gray"

  defp get_color_by_price_change(%{change_price: %Decimal{sign: 1}}),
    do: "green"

  defp get_color_by_price_change(%{change_price: %Decimal{sign: -1}}), do: "red"
end
