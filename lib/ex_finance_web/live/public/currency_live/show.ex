defmodule ExFinanceWeb.Public.CurrencyLive.Show do
  use ExFinanceWeb, :live_view
  use ExFinanceWeb.Navigation, :action

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency
  alias ExFinanceWeb.Utils.DatetimeUtils

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :update_chart, 50)
    end

    {:ok,
     socket
     |> assign_currencies()
     |> assign_interval()}
  end

  @impl true
  def handle_event("interval_change", %{"interval" => interval}, socket) do
    interval = String.to_existing_atom(interval)
    Process.send_after(self(), :update_chart, 50)

    {:noreply,
     socket
     |> assign_interval(interval)}
  end

  @impl true
  def handle_info(:update_chart, socket) do
    with %Currency{
           type: type,
           supplier_name: supplier_name
         } <- socket.assigns.currency,
         {:ok, history} <-
           Currencies.fetch_currency_history(
             supplier_name,
             type,
             socket.assigns.interval
           ) do
      all_series =
        build_all_series(
          socket.assigns.currencies
          |> Enum.filter(&(&1.id != socket.assigns.currency.id)),
          socket.assigns.interval
        )

      dataset = build_dataset(socket.assigns.currency, history, by: :trend)

      socket =
        Enum.reduce(
          dataset ++ List.flatten(all_series),
          socket,
          fn data, acc ->
            push_event(acc, "reset-dataset", %{label: data.label})
          end
        )

      socket =
        Enum.reduce(
          dataset ++ List.flatten(all_series),
          socket,
          fn data, acc ->
            push_event(acc, "new-point", data)
          end
        )

      {:noreply, socket}
    else
      _error ->
        {:noreply,
         socket
         |> push_event("reset-dataset", %{label: socket.assigns.currency.name})
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
     |> assign_header_action()
     |> assign(
       :section_title,
       gettext("%{cedear} price", cedear: currency.name)
     )
     |> assign(:currency, currency)}
  end

  # ----------------------------------------------------------------------------
  # Assignment functions
  #

  defp assign_currencies(socket) do
    currencies =
      Currencies.list_currencies()
      |> Enum.filter(
        &(&1.type in ["blue", "bna", "official", "ccl", "mep", "crypto"])
      )

    assign(socket, :currencies, currencies)
  end

  @spec assign_interval(Phoenix.LiveView.Socket.t(), Currencies.interval()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_interval(socket, interval \\ :daily),
    do: assign(socket, :interval, interval)

  defp build_all_series(currencies, interval) do
    Enum.map(currencies, fn %Currency{
                              type: type,
                              supplier_name: supplier_name
                            } = currency ->
      with {:ok, history} <-
             Currencies.fetch_currency_history(supplier_name, type, interval) do
        build_dataset(currency, history, by: :type)
      end
    end)
  end

  @spec build_dataset(
          Currency.t(),
          [
            {NaiveDateTime.t(), Currency.t()}
          ],
          keyword()
        ) :: [map()]
  defp build_dataset(currency, currency_history, params) do
    dataset_trend =
      currency_history
      |> Enum.reduce([], fn
        {_ts, %Currency{info_type: :market, sell_price: price}}, acc ->
          acc ++ [price]

        {_ts, %Currency{info_type: :reference, variation_price: price}}, acc ->
          acc ++ [price]

        _other, acc ->
          acc
      end)
      |> Enum.reverse()
      |> get_dataset_trend

    {background_color, border_color, hover_background_color} =
      get_chart_colors(Keyword.fetch!(params, :by), currency, dataset_trend)

    currency_history
    |> Enum.reduce([], fn
      {datetime,
       %Currency{name: currency_name, info_type: :market, sell_price: price}},
      acc ->
        acc ++
          [
            %{
              data_label: get_datetime_label(datetime),
              label: currency_name,
              value: price,
              background_color: background_color,
              border_color: border_color,
              hover_background_color: hover_background_color,
              hover_border_color: hover_background_color
            }
          ]

      {datetime,
       %Currency{
         name: currency_name,
         info_type: :reference,
         variation_price: price
       }},
      acc ->
        acc ++
          [
            %{
              data_label: get_datetime_label(datetime),
              label: currency_name,
              value: price,
              background_color: background_color,
              border_color: border_color,
              hover_background_color: hover_background_color,
              hover_border_color: hover_background_color
            }
          ]

      _other, acc ->
        acc
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

  defp get_chart_colors(:trend, _currency, dataset_trend) do
    get_colors_by_trend(get_dataset_trend(dataset_trend))
  end

  defp get_chart_colors(:type, %Currency{} = c, _dataset_trend) do
    get_rgb_color_by_currency_type(c)
  end

  defp get_colors_by_trend(:notrend),
    do:
      {"rgba(203, 213, 225, 1)", "rgba(100, 116, 139, 1)",
       "rgba(100, 116, 139, 1)"}

  defp get_colors_by_trend(:bullish),
    do:
      {"rgba(167, 243, 208, 1)", "rgba(16, 185, 129, 1)",
       "rgba(16, 185, 129, 1)"}

  defp get_colors_by_trend(:bearish),
    do:
      {"rgba(253, 164, 175, 1)", "rgba(244, 63, 94, 1)", "rgba(244, 63, 94, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "bna"}),
    do:
      {"rgba(185, 248, 207, 0.2)", "rgba(0, 201, 81, 0.4)",
       "rgba(0, 201, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "euro"}),
    do:
      {"rgba(255, 184, 106, 0.2)", "rgba(255, 105, 0, 0.4)",
       "rgba(255, 105, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "blue"}),
    do:
      {"rgba(142, 197, 255, 0.2)", "rgba(43, 127, 255, 0.4)",
       "rgba(43, 127, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "tourist"}),
    do:
      {"rgba(255, 161, 173, 0.2)", "rgba(255, 32, 86, 0.4)",
       "rgba(255, 32, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "crypto"}),
    do:
      {"rgba(255, 210, 48, 0.2)", "rgba(253, 154, 0, 0.4)",
       "rgba(253, 154, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "ccl"}),
    do:
      {"rgba(116, 212, 255, 0.2)", "rgba(0, 166, 244, 0.4)",
       "rgba(0, 166, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "luxury"}),
    do:
      {"rgba(163, 179, 255, 0.2)", "rgba(97, 95, 255, 0.4)",
       "rgba(97, 95, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "official"}),
    do:
      {"rgba(94, 233, 181, 0.2)", "rgba(0, 188, 125, 0.4)",
       "rgba(0, 188, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "mep"}),
    do:
      {"rgba(83, 234, 253, 0.2)", "rgba(0, 184, 219, 0.4)",
       "rgba(0, 184, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "wholesaler"}),
    do:
      {"rgba(70, 236, 213, 0.2)", "rgba(0, 187, 167, 0.4)",
       "rgba(0, 187, 255, 1)"}

  def get_rgb_color_by_currency_type(%Currency{type: "future"}),
    do:
      {"rgba(196, 180, 255, 0.2)", "rgba(142, 81, 255, 0.4)",
       "rgba(142, 81, 255, 1)"}

  defp get_datetime_label(%DateTime{} = datetime),
    do:
      DatetimeUtils.human_readable_datetime(datetime,
        shift_timezone: true,
        only_date: true
      )

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

  # ----------------------------------------------------------------------------
  # Render functions
  #

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

  # ----------------------------------------------------------------------------
  # Colors functions
  #

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
    <canvas id="chart-canvas" phx-update="ignore" phx-hook="LineChart" />
    """
  end

  defp render_header_action(assigns) do
    ~H"""
    <.navigation_back navigate={~p"/currencies"} />
    """
  end
end
