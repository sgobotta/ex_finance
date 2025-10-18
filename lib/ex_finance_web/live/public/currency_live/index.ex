defmodule ExFinanceWeb.Public.CurrencyLive.Index do
  use ExFinanceWeb, :live_view
  use ExFinanceWeb.Navigation, :action

  use ExFinance.Presence, {:tracker, [pubsub_server: ExFinance.PubSub]}

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency
  alias ExFinanceWeb.Utils.DatetimeUtils

  @impl true
  def mount(_params, session, socket) do
    :ok = Currencies.subscribe_currencies()

    session_id = get_session_id(session)

    currencies = Currencies.list_currencies()

    {:ok,
     socket
     |> assign_session_id(session_id)
     |> assign_presences()
     |> assign_participants(session_id)
     |> assign_disclaimer_content()
     |> assign_show_calculator(false)
     |> assign_selected_currency(nil)
     |> assign_conversion_form()
     |> assign_currencies(currencies)
     |> stream(
       :currencies,
       currencies |> Currencies.sort_currencies()
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    presence_topic = "currencies"

    if connected?(socket) do
      track_and_subscribe(presence_topic, socket.assigns.session_id, %{
        joined_at: inspect(System.system_time(:second))
      })
    end

    {:noreply,
     socket
     |> assign_presences(list_presence(presence_topic))
     |> assign_header_action()
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("toggle_calculator", %{"currency_id" => currency_id}, socket) do
    %Currency{} =
      currency =
      Enum.find(socket.assigns.currencies, fn c ->
        c.id == currency_id
      end)

    socket =
      if socket.assigns.show_calculator do
        socket
        |> assign_show_calculator(false)
        |> assign_selected_currency(nil)
      else
        socket
        |> assign_show_calculator(true)
        |> assign_selected_currency(currency)
      end

    {:noreply, socket}
  end

  def handle_event(
        "validate_conversion",
        %{"_target" => ["ars_amount"], "ars_amount" => ars_amount},
        socket
      ) do
    input_value =
      if ars_amount == "" do
        Decimal.new(0)
      else
        ars_amount
        |> Decimal.new()
      end
      |> Decimal.round(2)

    selected_currency =
      Enum.find(
        socket.assigns.currencies,
        fn currency -> currency.id == socket.assigns.selected_currency.id end
      )

    usd_amount =
      if selected_currency do
        Decimal.div(input_value, selected_currency.sell_price)
      else
        Decimal.new(0)
      end
      |> Decimal.round(2)

    conversion_form = %{
      "ars_amount" => ars_amount,
      "usd_amount" => usd_amount
    }

    {:noreply, assign_conversion_form(socket, conversion_form)}
  end

  def handle_event(
        "validate_conversion",
        %{"_target" => ["usd_amount"], "usd_amount" => usd_amount},
        socket
      ) do
    input_value =
      if usd_amount == "" do
        Decimal.new(0)
      else
        usd_amount
        |> Decimal.new()
      end
      |> Decimal.round(2)

    selected_currency =
      Enum.find(
        socket.assigns.currencies,
        fn currency -> currency.id == socket.assigns.selected_currency.id end
      )

    ars_amount =
      if selected_currency do
        Decimal.mult(input_value, selected_currency.sell_price)
      else
        Decimal.new(0)
      end
      |> Decimal.round(2)

    conversion_form = %{
      "ars_amount" => ars_amount,
      "usd_amount" => usd_amount
    }

    {:noreply, assign_conversion_form(socket, conversion_form)}
  end

  @spec assign_show_calculator(
          Phoenix.LiveView.Socket.t(),
          boolean()
        ) :: Phoenix.LiveView.Socket.t()
  defp assign_show_calculator(socket, show_calculator),
    do: assign(socket, :show_calculator, show_calculator)

  @spec assign_selected_currency(
          Phoenix.LiveView.Socket.t(),
          Currency.t() | nil
        ) :: Phoenix.LiveView.Socket.t()
  defp assign_selected_currency(socket, currency),
    do: assign(socket, :selected_currency, currency)

  @spec track_and_subscribe(String.t(), String.t(), map()) :: :ok
  defp track_and_subscribe(topic, presence_id, meta) do
    {:ok, _ref} = track_presence(self(), topic, presence_id, meta)
    :ok = subscribe_presence(topic)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Dollar quotes"))
    |> assign(:section_title, gettext("Dollar quotes"))
  end

  @impl true
  def handle_info({:currency_updated, %Currency{} = new_currency}, socket) do
    currencies =
      Enum.map(socket.assigns.currencies, fn %Currency{} = currency ->
        if currency.id == new_currency.id, do: new_currency, else: currency
      end)

    socket =
      socket
      |> assign_currencies(currencies)
      |> stream_insert(:currencies, new_currency, at: -1)

    {:noreply, socket}
  end

  @spec on_presence_diff(Phoenix.LiveView.Socket.t()) ::
          Phoenix.LiveView.Socket.t()
  def on_presence_diff(socket) do
    socket
    |> assign_participants(socket.assigns.session_id)
    |> assign_disclaimer_content()
  end

  # ----------------------------------------------------------------------------
  # Assignment functions
  #
  defp assign_session_id(socket, session_id),
    do: assign(socket, :session_id, session_id)

  defp get_session_id(session), do: session["_csrf_token"]

  defp assign_disclaimer_content(
         %{assigns: %{presence_participants: 0}} = socket
       ) do
    socket
    |> assign(:disclaimer_content, nil)
    |> assign(:show_presence, false)
  end

  defp assign_disclaimer_content(
         %{assigns: %{presence_participants: presence_participants}} = socket
       ) do
    disclaimer_content =
      ngettext(
        "You and other user are browsing dollar quotes",
        "You and %{users} more users are browsing dollar quotes",
        presence_participants,
        users: presence_participants
      )

    socket
    |> assign(:disclaimer_content, disclaimer_content)
    |> assign(:show_presence, true)
  end

  defp assign_conversion_form(socket) do
    assign_conversion_form(socket, %{
      "ars_amount" => Decimal.new(0) |> Decimal.round(2),
      "usd_amount" => Decimal.new(0) |> Decimal.round(2)
    })
  end

  defp assign_conversion_form(socket, conversion_form) do
    assign(socket, :conversion_form, conversion_form)
  end

  defp assign_currencies(socket, currencies) do
    assign(socket, :currencies, currencies)
  end

  # ----------------------------------------------------------------------------
  # Helper functions
  #
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

  defp render_header_action(assigns) do
    ~H"""
    <.navigation_back navigate={~p"/"} />
    """
  end

  defp render_currency_name(%Currency{name: name}), do: name

  # ----------------------------------------------------------------------------
  # Misc functions
  #

  defp card_container_id(currency_id), do: "currencies-#{currency_id}-card"
  defp variation_id(currency_id), do: "currency-variation-#{currency_id}"
  defp details_id(currency_id), do: "currency-details-#{currency_id}"

  defp variation_animation_class, do: "animate-slide-in-right"
  defp details_animation_class, do: "animate-twiggle"

  defp animation_dataset(currency_id) do
    [
      %{
        "elementId" => variation_id(currency_id),
        "classes" => [variation_animation_class()]
      },
      %{
        "elementId" => details_id(currency_id),
        "classes" => [details_animation_class()]
      }
    ]
    |> Jason.encode!()
  end
end
