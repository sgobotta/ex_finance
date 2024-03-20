defmodule ExFinanceWeb.Public.CedearsLive.Show do
  @moduledoc false
  alias ExFinnhub.StockPrice
  use ExFinanceWeb, :live_view

  use ExFinance.Presence, {:tracker, [pubsub_server: ExFinance.PubSub]}

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency
  alias ExFinance.Instruments
  alias ExFinance.Instruments.{Cedear, CedearPriceCalc}

  alias ExFinnhub.StockPrices

  @fetch_interval :timer.seconds(30)

  # ----------------------------------------------------------------------------
  # Lifecycle
  #

  @impl true
  def mount(_params, session, socket) do
    :ok = Currencies.subscribe_currencies()
    ccl_currency = Currencies.get_by_type("ccl")

    cedear_price_calc = %CedearPriceCalc{
      underlying_currency_id: ccl_currency.id
    }

    changeset = Instruments.change_cedear_price_calc(cedear_price_calc)

    session_id = get_session_id(session)

    {:ok,
     socket
     |> assign_changeset(changeset)
     |> assign_form(changeset)
     |> assign_cedear(nil)
     |> assign_currency(ccl_currency)
     |> assign_cedear_price_calc(cedear_price_calc)
     |> assign_stock_price(nil)
     |> assign_average_stock_price(Decimal.new(0))
     |> assign_stock_price_changes()
     |> assign_timeleft_to_next_update(nil)
     |> assign_countdown_ref(nil)
     |> assign_session_id(session_id)
     |> assign_presences()
     |> assign_participants(session_id)
     |> assign_disclaimer_content()}
  end

  # ----------------------------------------------------------------------------
  # Handlers
  #

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    cedear = Instruments.get_cedear!(id)
    presence_topic = "cedears:" <> id

    if connected?(socket) do
      track_and_subscribe(presence_topic, socket.assigns.session_id, %{
        joined_at: inspect(System.system_time(:second))
      })
    end

    {:ok, stock_price_worker_pid,
     {maybe_stock_price, maybe_millis_to_next_update}} =
      StockPrices.subscribe_stock_price(cedear.symbol)

    socket =
      case maybe_stock_price do
        nil ->
          socket

        %StockPrice{} = stock_price ->
          stock_price_changes =
            CedearPriceCalc.calculate_stock_price_changes(
              cedear,
              socket.assigns.changeset,
              stock_price
            )

          assign_stock_price_changes(socket, stock_price_changes)
      end

    schedule_heartbeat(stock_price_worker_pid)
    maybe_schedule_countdown(maybe_millis_to_next_update)

    presences = list_presence(presence_topic)

    {:noreply,
     socket
     |> assign_stock_price(maybe_stock_price)
     |> assign(:page_title, cedear.name)
     |> assign(:section_title, gettext("%{cedear} price", cedear: cedear.name))
     |> assign_cedear(cedear)
     |> assign_timeleft_to_next_update(maybe_millis_to_next_update)
     |> assign_presences(presences)
     |> assign_participants(socket.assigns.session_id)
     |> assign_disclaimer_content()}
  end

  @spec track_and_subscribe(String.t(), String.t(), map()) :: :ok
  defp track_and_subscribe(topic, presence_id, meta) do
    {:ok, _ref} = track_presence(self(), topic, presence_id, meta)
    :ok = subscribe_presence(topic)
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
  def handle_info(
        {:new_stock_price,
         {%ExFinnhub.StockPrice{} = stock_price, maybe_millis_to_next_update}},
        socket
      ) do
    stock_price_changes =
      CedearPriceCalc.calculate_stock_price_changes(
        socket.assigns.cedear,
        socket.assigns.changeset,
        stock_price
      )

    maybe_schedule_countdown(maybe_millis_to_next_update)

    {:noreply,
     socket
     |> assign_stock_price(stock_price)
     |> assign_stock_price_changes(stock_price_changes)
     |> assign_timeleft_to_next_update(maybe_millis_to_next_update)}
  end

  @impl true
  def handle_info({:heartbeat, pid}, socket) do
    :ok = ExFinnhub.StockPrices.heartbeat(pid)
    schedule_heartbeat(pid)
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:timeleft_to_next_update, 0},
        %{assigns: %{countdown_ref: countdown_ref}} = socket
      ) do
    if countdown_ref != nil do
      Process.cancel_timer(countdown_ref)
    end

    {:noreply, socket}
  end

  def handle_info({:timeleft_to_next_update, nil}, socket),
    do: {:noreply, socket}

  def handle_info(
        {:timeleft_to_next_update, timeleft},
        %{assigns: %{countdown_ref: countdown_ref}} = socket
      ) do
    if countdown_ref != nil do
      Process.cancel_timer(countdown_ref)
    end

    countdown_ref = maybe_schedule_countdown(timeleft)

    {:noreply,
     socket
     |> assign_timeleft_to_next_update(timeleft)
     |> assign_countdown_ref(countdown_ref)}
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

  def on_presence_diff(socket) do
    socket
    |> assign_participants(socket.assigns.session_id)
    |> assign_disclaimer_content()
  end

  # ----------------------------------------------------------------------------
  # Assignment functions
  #

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

  defp assign_timeleft_to_next_update(socket, timeleft_to_next_update),
    do: assign(socket, :timeleft_to_next_update, timeleft_to_next_update)

  @spec assign_countdown_ref(Phoenix.LiveView.Socket.t(), reference() | nil) ::
          Phoenix.LiveView.Socket.t()
  defp assign_countdown_ref(socket, countdown_ref),
    do: assign(socket, :countdown_ref, countdown_ref)

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
        "You and other user are browsing %{cedear} quotes",
        "You and %{users} more users are browsing %{cedear} quotes",
        presence_participants,
        users: presence_participants,
        cedear: socket.assigns.cedear.name
      )

    socket
    |> assign(:disclaimer_content, disclaimer_content)
    |> assign(:show_presence, true)
  end

  # ----------------------------------------------------------------------------
  # Render functions
  #

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
        %{fair_cedear_price: %Decimal{} = fair_cedear_price} = _changes
      ) do
    "#{fair_cedear_price}"
  end

  @spec render_timeleft(number()) :: integer()
  def render_timeleft(milliseconds), do: round(milliseconds / 1000)

  # ----------------------------------------------------------------------------
  # Colors functions
  #

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

  # ----------------------------------------------------------------------------
  # Timers functions
  #

  @spec schedule_heartbeat(pid()) :: reference()
  defp schedule_heartbeat(pid),
    do: Process.send_after(self(), {:heartbeat, pid}, @fetch_interval)

  @spec maybe_schedule_countdown(non_neg_integer() | nil) :: reference() | nil
  defp maybe_schedule_countdown(nil), do: nil

  defp maybe_schedule_countdown(millis) do
    next_tick = :timer.seconds(1)

    _timeleft_ref =
      Process.send_after(
        self(),
        {:timeleft_to_next_update, millis - next_tick},
        next_tick
      )
  end
end
