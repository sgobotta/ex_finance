defmodule ExFinanceWeb.Public.CurrencyLive.Show do
  use ExFinanceWeb, :live_view

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency
  alias ExFinanceWeb.Utils.DatetimeUtils

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :update_chart, 500)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_chart, socket) do
    with %Currency{
           type: type,
           name: currency_name,
           supplier_name: supplier_name
         } <- socket.assigns.currency,
         {:ok, history} <-
           Currencies.fetch_currency_history(supplier_name, type) do
      socket =
        Enum.reduce(build_dataset(currency_name, history), socket, fn data,
                                                                      acc ->
          push_event(acc, "new-point", data)
        end)

      {:noreply, socket}
    else
      _error ->
        {:noreply,
         socket
         |> push_event("new-point", %{
           data_label: get_datetime_label(DateTime.utc_now()),
           label: socket.assigns.currency.name,
           value: 0
         })
         |> put_flash(
           :error,
           gettext("There was an error loading the price chart")
         )}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    currency = Currencies.get_currency!(id)

    {:noreply,
     socket
     |> assign(:page_title, currency.name)
     |> assign(:section_title, "Cotizaciones de #{currency.name}")
     |> assign(:currency, currency)}
  end

  @spec build_dataset(String.t(), [
          {NaiveDateTime.t(), Currency.t()}
        ]) :: [map()]
  defp build_dataset(currency_name, currency_history) do
    dataset_trend =
      currency_history
      |> Enum.map(fn
        {_ts, %Currency{info_type: :market, sell_price: price}} -> price
        {_ts, %Currency{info_type: :reference, variation_price: price}} -> price
      end)
      |> Enum.reverse()
      |> get_dataset_trend

    {background_color, border_color} = get_chart_colors(dataset_trend)

    Enum.map(currency_history, fn
      {datetime, %Currency{info_type: :market, sell_price: price}} ->
        %{
          data_label: get_datetime_label(datetime),
          label: currency_name,
          value: price,
          background_color: background_color,
          border_color: border_color
        }

      {datetime, %Currency{info_type: :reference, variation_price: price}} ->
        %{
          data_label: get_datetime_label(datetime),
          label: currency_name,
          value: price,
          background_color: background_color,
          border_color: border_color
        }
    end)
  end

  defp get_dataset_trend([]), do: :bullish
  defp get_dataset_trend([_price]), do: :bullish

  defp get_dataset_trend([last_price, price | _rest])
       when last_price == price do
    :notrend
  end

  defp get_dataset_trend([last_price, price | _rest]) when last_price > price,
    do: :bullish

  defp get_dataset_trend(_price_history), do: :bearish

  defp get_chart_colors(:notrend),
    do: {"rgba(203, 213, 225, 1)", "rgba(100, 116, 139, 1)"}

  defp get_chart_colors(:bullish),
    do: {"rgba(167, 243, 208, 1)", "rgba(16, 185, 129, 1)"}

  defp get_chart_colors(:bearish),
    do: {"rgba(253, 164, 175, 1)", "rgba(244, 63, 94, 1)"}

  defp get_datetime_label(%DateTime{} = datetime),
    do: DatetimeUtils.human_readable_datetime(datetime, :shift_timezone)

  defp get_color_by_currency_type(%Currency{type: "bna"}), do: "green"
  defp get_color_by_currency_type(%Currency{type: "euro"}), do: "orange"
  defp get_color_by_currency_type(%Currency{type: "blue"}), do: "blue"
  defp get_color_by_currency_type(%Currency{type: "tourist"}), do: "rose"
  defp get_color_by_currency_type(%Currency{type: "crypto"}), do: "amber"
  defp get_color_by_currency_type(%Currency{type: "ccl"}), do: "sky"
  defp get_color_by_currency_type(%Currency{type: "luxury"}), do: "indigo"
  defp get_color_by_currency_type(%Currency{type: "official"}), do: "green"
  defp get_color_by_currency_type(%Currency{type: "mep"}), do: "sky"
  defp get_color_by_currency_type(%Currency{type: "wholesaler"}), do: "emerald"
  defp get_color_by_currency_type(%Currency{type: "future"}), do: "emerald"

  defp render_variation_percent(%Currency{variation_percent: variation_percent}),
    do: "#{variation_percent}%"

  defp render_update_time(%Currency{price_updated_at: datetime}),
    do: DatetimeUtils.human_readable_datetime(datetime)

  defp render_price(price), do: "$#{price}"

  defp render_info_type(%Currency{info_type: :market}), do: "Precio de mercado"

  defp render_info_type(%Currency{info_type: :reference}),
    do: "Precio referencia"

  defp render_spread(%Currency{
         info_type: :market,
         sell_price: sell_price,
         buy_price: buy_price
       }),
       do: "$#{Decimal.sub(sell_price, buy_price)}"

  defp get_color_by_price_direction(%Currency{
         variation_percent: %Decimal{coef: 0}
       }),
       do: "gray"

  defp get_color_by_price_direction(%Currency{
         variation_percent: %Decimal{sign: -1}
       }),
       do: "red"

  defp get_color_by_price_direction(%Currency{
         variation_percent: %Decimal{sign: 1}
       }),
       do: "green"

  defp render_chart(assigns) do
    ~H"""
    <canvas
      id="chart-canvas"
      phx-update="ignore"
      phx-hook="LineChart"
      height="200"
      width="300"
    />
    """
  end
end
