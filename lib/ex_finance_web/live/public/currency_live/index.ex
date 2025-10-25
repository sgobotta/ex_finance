defmodule ExFinanceWeb.Public.CurrencyLive.Index do
  use ExFinanceWeb, :live_view
  use ExFinanceWeb.Navigation, :action

  use ExFinance.Presence, {:tracker, [pubsub_server: ExFinance.PubSub]}

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Converter
  alias ExFinance.Currencies.Currency

  alias ExFinanceWeb.Utils.DatetimeUtils

  @impl true
  def mount(_params, session, socket) do
    :ok = Currencies.subscribe_currencies()

    session_id = get_session_id(session)

    currencies = Currencies.list_allowed_currencies()

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
      if socket.assigns.show_calculator and
           socket.assigns.selected_currency.id == currency.id do
        socket
        |> assign_show_calculator(false)
        |> assign_selected_currency(nil)
      else
        socket =
          socket
          |> assign_show_calculator(true)
          |> assign_selected_currency(currency)
          |> push_event("show_conversion_banner", %{})

        usd_amount = socket.assigns.conversion_form["usd_amount"]

        input_value = parse_input_value(usd_amount)

        ars_amount = convert_usd_to_ars(socket, input_value)

        conversion_form =
          Map.put(
            socket.assigns.conversion_form,
            "ars_amount",
            ars_amount
          )

        assign(socket, :conversion_form, conversion_form)
      end

    {:noreply, socket}
  end

  def handle_event(
        "validate_conversion",
        %{"_target" => ["ars_amount"], "ars_amount" => ars_amount},
        socket
      ) do
    input_value = parse_input_value(ars_amount)

    usd_amount = convert_ars_to_usd(socket, input_value)

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

    ars_amount = convert_usd_to_ars(socket, input_value)

    conversion_form = %{
      "ars_amount" => ars_amount,
      "usd_amount" => usd_amount
    }

    {:noreply, assign_conversion_form(socket, conversion_form)}
  end

  def handle_event(
        "set_market_price_type",
        %{"market_price_type" => market_price_type},
        socket
      ) do
    {:noreply,
     on_price_type_update(
       socket,
       market_price_type |> String.to_existing_atom()
     )}
  end

  def handle_event("update_price_type", %{"key" => "Escape"}, socket) do
    {:noreply, assign_show_calculator(socket, false)}
  end

  def handle_event(
        "update_price_type",
        %{"key" => "c"},
        %{assigns: %{market_price_type: market_price_type}} = socket
      )
      when market_price_type != nil do
    {:noreply,
     on_price_type_update(
       socket,
       :buy_price
     )}
  end

  def handle_event(
        "update_price_type",
        %{"key" => "b"},
        %{assigns: %{market_price_type: market_price_type}} = socket
      )
      when market_price_type != nil do
    {:noreply, on_price_type_update(socket, :buy_price)}
  end

  def handle_event(
        "update_price_type",
        %{"key" => "v"},
        %{assigns: %{market_price_type: market_price_type}} = socket
      )
      when market_price_type != nil do
    {:noreply, on_price_type_update(socket, :sell_price)}
  end

  def handle_event(
        "update_price_type",
        %{"key" => "s"},
        %{assigns: %{market_price_type: market_price_type}} = socket
      )
      when market_price_type != nil do
    {:noreply, on_price_type_update(socket, :sell_price)}
  end

  def handle_event("update_price_type", _params, socket), do: {:noreply, socket}

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
  defp assign_selected_currency(socket, currency) do
    case currency do
      nil ->
        socket
        |> assign(:selected_currency, nil)
        |> assign_price_type(nil)

      %Currency{info_type: :reference} = currency ->
        socket
        |> assign(:selected_currency, currency)
        |> assign_price_type(nil)

      %Currency{info_type: :market} = currency ->
        socket
        |> assign(:selected_currency, currency)
        |> assign_price_type(:buy_price)
    end
  end

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

  defp assign_price_type(socket, price_type) do
    assign(socket, :market_price_type, price_type)
  end

  # ----------------------------------------------------------------------------
  # Helper functions
  #
  @spec get_selected_currency(Phoenix.LiveView.Socket.t()) ::
          Currency.t() | nil
  defp get_selected_currency(socket),
    do:
      Enum.find(
        socket.assigns.currencies,
        fn currency -> currency.id == socket.assigns.selected_currency.id end
      )

  @spec convert_ars_to_usd(
          Phoenix.LiveView.Socket.t(),
          Decimal.t()
        ) :: Decimal.t()
  defp convert_ars_to_usd(socket, input_value) do
    selected_currency = get_selected_currency(socket)

    Converter.ars_to_usd(
      selected_currency,
      input_value,
      socket.assigns.market_price_type
    )
  end

  @spec convert_usd_to_ars(
          Phoenix.LiveView.Socket.t(),
          Decimal.t()
        ) :: Decimal.t()
  defp convert_usd_to_ars(socket, input_value) do
    selected_currency = get_selected_currency(socket)

    Converter.usd_to_ars(
      selected_currency,
      input_value,
      socket.assigns.market_price_type
    )
  end

  @spec parse_input_value(String.t()) :: Decimal.t()
  defp parse_input_value(input) do
    if input == "" do
      Decimal.new(0)
    else
      input
      |> Decimal.new()
    end
    |> Decimal.round(2)
  end

  defp on_price_type_update(socket, price_type) do
    socket = assign_price_type(socket, price_type)
    usd_amount = parse_input_value(socket.assigns.conversion_form["usd_amount"])
    ars_amount = convert_usd_to_ars(socket, usd_amount)

    conversion_form =
      Map.put(
        socket.assigns.conversion_form,
        "ars_amount",
        ars_amount
      )

    socket
    |> assign_conversion_form(conversion_form)
  end

  # ----------------------------------------------------------------------------
  # Rendering Helper functions
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
  defp get_color_by_currency_type(%Currency{type: "wholesaler"}), do: "indigo"
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

  # ----------------------------------------------------------------------------
  # Misc functions
  #

  defp card_container_id(currency_id), do: "currencies-#{currency_id}-card"
  defp variation_id(currency_id), do: "currency-variation-#{currency_id}"
  defp details_id(currency_id), do: "currency-details-#{currency_id}"

  defp variation_animation_class, do: "animate-slide-in-right"
  defp details_animation_class, do: "animate-twiggle"

  defp currency_card_animation_dataset(currency_id) do
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
