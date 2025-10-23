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
        "rounded-t-lg z-50 shadow-2xl"
      ]}
      phx-hook="AnimateCurrencyBanner"
      data-animations={banner_animation_dataset()}
    >
      <%= if @show_calculator do %>
        <div class="grid grid-cols-2 border-b-[1px] border-zinc-200 mx-4 mt-[0.75rem]">
          <div class="justify-self-start pb-2">
            <h3 class="text-center text-lg font-normal text-zinc-700 dark:text-zinc-100 cursor-default select-none">
              <%= render_currency_name(@selected_currency) %>
            </h3>
          </div>
          <div class="justify-self-end pb-2 duration-300 opacity-20 hover:opacity-100">
            <button
              phx-click="toggle_calculator"
              phx-value-currency_id={@selected_currency.id}
              class="hover:text-red-500 dark:hover:text-red-500"
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
        <div phx-window-keyup="update_price_type" class="mx-4 mt-4">
          <%= if @selected_currency.info_type == :market do %>
            <div class="grid grid-cols-2 gap-4 cursor-default text-xs select-none">
              <div class="justify-self-end">
                <div
                  class={[
                    "p-2 rounded-md inline-block",
                    "bg-zinc-200 dark:bg-zinc-700 ",
                    "#{if @market_price_type == :buy_price, do: "border-[1px] border-zinc-800 dark:border-zinc-200", else: "cursor-pointer"}",
                    "text-green-700 dark:text-green-300",
                    "transform duration-100 ease-linear",
                    "hover:shadow-outer-xs",
                    "flex flex-row"
                  ]}
                  phx-click="set_market_price_type"
                  phx-value-market_price_type="buy_price"
                >
                  <%= gettext("Buy") %> <%= render_price(
                    @selected_currency.buy_price
                  ) %>
                  <div class={[
                    "self-center",
                    "w-4 h-4 ml-2 rounded-sm",
                    "text-center",
                    "bg-zinc-200 text-zinc-500",
                    "dark:bg-zinc-800 dark:text-zinc-400",
                    "border-[1px] border-zinc-500",
                    "shadow-inner-xs"
                  ]}>
                    <%= gettext("Buy_Shortcut") %>
                  </div>
                </div>
              </div>
              <div class="justify-self-start">
                <div
                  class={[
                    "p-2 rounded-md inline-block",
                    "bg-zinc-200 dark:bg-zinc-700 ",
                    "border-[1px]",
                    "#{if @market_price_type == :sell_price, do: "border-zinc-800 dark:border-zinc-200", else: "border-white dark:border-zinc-800 cursor-pointer"}",
                    "text-red-700 dark:text-red-300",
                    "transform duration-100 ease-linear",
                    "hover:shadow-outer-xs",
                    "flex flex-row"
                  ]}
                  phx-click="set_market_price_type"
                  phx-value-market_price_type="sell_price"
                >
                  <%= gettext("Sell") %> <%= render_price(
                    @selected_currency.sell_price
                  ) %>
                  <div class={[
                    "self-center",
                    "w-4 h-4 ml-2 rounded-sm",
                    "text-center",
                    "bg-zinc-200 text-zinc-500",
                    "dark:bg-zinc-800 dark:text-zinc-400",
                    "border-[1px] border-zinc-500",
                    "shadow-inner-xs"
                  ]}>
                    <%= gettext("Sell_Shortcut") %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
          <%= if @selected_currency.info_type == :reference do %>
            <div class="flex flex-row items-center gap-4 cursor-default text-xs select-none justify-self-center">
              <div class="p-2 rounded-md bg-zinc-200 dark:bg-zinc-700 inline-block text-zinc-900 dark:text-zinc-200">
                <%= gettext("Reference Price") %> <%= render_price(
                  @selected_currency.variation_price
                ) %>
              </div>
            </div>
          <% end %>
        </div>
        <div class="p-4 pt-1 mt-4 flex flex-row">
          <.simple_form
            for={@conversion_form}
            id="conversion_form"
            phx-change="validate_conversion"
            class="w-full"
            container_classes="flex-row gap-4"
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
              class="shadow-inner-xs dark:shadow-dark-inner-xs !text-sky-500 font-bold dark:bg-zinc-700 select-text"
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
              class="shadow-inner-xs dark:shadow-dark-inner-xs !text-green-500 font-bold dark:bg-zinc-700 select-text"
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
