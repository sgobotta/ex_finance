defmodule ExFinanceWeb.CustomComponents.CalculatorBanner do
  @moduledoc """
  A banner component that shows a currency calculator at the bottom of the
  screen.
  """
  use ExFinanceWeb, :live_component

  alias ExFinance.Currencies.Currency

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "fixed bottom-0 w-full lg:w-1/2 lg:left-1/4",
        "bg-white dark:bg-zinc-800",
        "rounded-t-lg z-50"
      ]}
      phx-hook="AnimateCurrencyBanner"
      data-animations={banner_animation_dataset()}
    >
      <%= if @show_calculator do %>
        <div class="p-4 pb-1 flex justify-between items-center">
          <div>
            <h3 class="text-center text-lg font-semibold text-zinc-700 dark:text-zinc-100 cursor-default select-none">
              <%= render_currency_name(@selected_currency) %>
            </h3>
          </div>
          <div>
            <%= if @selected_currency.info_type == :market do %>
              <div class="flex flex-row items-center gap-4 cursor-default text-xs select-none">
                <div
                  class={[
                    "p-2 rounded-md inline-block",
                    "bg-zinc-200 dark:bg-zinc-700 ",
                    "#{if @market_price_type == :buy_price, do: "border-[1px] border-zinc-800 dark:border-zinc-200", else: "cursor-pointer"}",
                    "text-green-500"
                  ]}
                  phx-click="set_market_price_type"
                  phx-value-market_price_type="buy_price"
                >
                  <%= gettext("Buy") %> <%= render_price(
                    @selected_currency.buy_price
                  ) %>
                </div>
                <div
                  class={[
                    "p-2 rounded-md inline-block",
                    "bg-zinc-200 dark:bg-zinc-700 ",
                    "#{if @market_price_type == :sell_price, do: "border-[1px] border-zinc-800 dark:border-zinc-200", else: "cursor-pointer"}",
                    "text-red-500"
                  ]}
                  phx-click="set_market_price_type"
                  phx-value-market_price_type="sell_price"
                >
                  <%= gettext("Sell") %> <%= render_price(
                    @selected_currency.sell_price
                  ) %>
                </div>
              </div>
            <% end %>
            <%= if @selected_currency.info_type == :reference do %>
              <div class="flex flex-row items-center gap-4 cursor-default text-xs select-none">
                <div class="p-2 rounded-md bg-zinc-200 dark:bg-zinc-700 inline-block text-secondary">
                  <%= gettext("Reference Price") %> <%= render_price(
                    @selected_currency.variation_price
                  ) %>
                </div>
              </div>
            <% end %>
          </div>
          <div>
            <button
              phx-click="toggle_calculator"
              phx-value-currency_id={@selected_currency.id}
              class="text-zinc-700 dark:text-zinc-100 hover:text-red-500 dark:hover:text-red-500"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
        </div>
        <div class="p-4 pt-1 mt-4 flex flex-row">
          <.simple_form
            for={@conversion_form}
            id="conversion_form"
            phx-change="validate_conversion"
            class="w-full"
            container_classes="flex-row gap-8"
          >
            <.input_pill
              container_class="w-full"
              name="ars_amount"
              field={@conversion_form["ars_amount"]}
              type="number"
              label="ARS"
              pill_color="bg-sky-500"
              value={@conversion_form["ars_amount"]}
              min={0}
              step={100}
              required
              class="shadow-inner-xs dark:shadow-dark-inner-xs !text-sky-500 font-bold dark:bg-zinc-700"
            />
            <.input_pill
              container_class="w-full"
              field={@conversion_form["usd_amount"]}
              name="usd_amount"
              type="number"
              label="USD"
              pill_color="bg-green-500"
              value={@conversion_form["usd_amount"]}
              min={0}
              required
              class="shadow-inner-xs dark:shadow-dark-inner-xs !text-green-500 font-bold dark:bg-zinc-700"
            />
          </.simple_form>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_price(price), do: "$#{price}"

  defp render_currency_name(%Currency{name: name}), do: name

  defp banner_animation_dataset do
    %{
      "elementId" => "calculator-banner",
      "classes" => []
    }
    |> Jason.encode!()
  end
end
