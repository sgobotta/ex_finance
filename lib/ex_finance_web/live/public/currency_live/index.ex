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

    {:ok,
     socket
     |> assign_session_id(session_id)
     |> assign_presences()
     |> assign_participants(session_id)
     |> assign_disclaimer_content()
     |> assign_show_calculator(false)
     |> assign_selected_currency_id(nil)
     |> stream(
       :currencies,
       Currencies.list_currencies() |> Currencies.sort_currencies()
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
    socket =
      if socket.assigns.show_calculator do
        socket
        |> assign_show_calculator(false)
        |> assign_selected_currency_id(nil)
      else
        socket
        |> assign_show_calculator(true)
        |> assign_selected_currency_id(currency_id)
      end

    {:noreply, socket}
  end

  @spec assign_show_calculator(
          Phoenix.LiveView.Socket.t(),
          boolean()
        ) :: Phoenix.LiveView.Socket.t()
  defp assign_show_calculator(socket, show_calculator),
    do: assign(socket, :show_calculator, show_calculator)

  @spec assign_selected_currency_id(
          Phoenix.LiveView.Socket.t(),
          String.t() | nil
        ) :: Phoenix.LiveView.Socket.t()
  defp assign_selected_currency_id(socket, currency_id),
    do: assign(socket, :selected_currency_id, currency_id)

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
  def handle_info({:currency_updated, %Currency{} = currency}, socket) do
    {:noreply, stream_insert(socket, :currencies, currency, at: -1)}
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
