defmodule ExFinnhub.StockPrices.Channels do
  @moduledoc false

  require Logger

  @type message :: atom() | {atom(), any()} | {atom(), binary(), any()}

  # ----------------------------------------------------------------------------
  # Topics
  #
  @stock_prices_topic "stock-prices"

  # ----------------------------------------------------------------------------
  # Events
  #
  @new_stock_price :new_stock_price

  @doc """
  Returns the #{@stock_prices_topic} topic.
  """
  @spec stock_prices_topic(binary()) :: binary()
  def stock_prices_topic(symbol), do: "#{@stock_prices_topic}:#{symbol}"

  @doc """
  Returns the message name for #{@new_stock_price} events.
  """
  @spec new_stock_price() :: :new_stock_price
  def new_stock_price, do: @new_stock_price

  @doc """
  Subscribes to the #{@stock_prices_topic} topic.
  """
  @spec subscribe_stock_prices_topic(binary()) :: :ok | {:error, any()}
  def subscribe_stock_prices_topic(symbol),
    do: subscribe(stock_prices_topic(symbol))

  @doc """
  Broadcasts a #{@new_stock_price} message.
  """
  @spec broadcast_new_stock_price!(binary(), any()) :: :ok
  def broadcast_new_stock_price!(symbol, payload),
    do:
      broadcast!(
        stock_prices_topic(symbol),
        {new_stock_price(), payload}
      )

  @spec broadcast!(binary(), message()) :: :ok
  defp broadcast!(topic, message),
    do: Phoenix.PubSub.broadcast!(ExFinance.PubSub, topic, message)

  @spec subscribe(binary()) :: :ok | {:error, any()}
  defp subscribe(topic), do: Phoenix.PubSub.subscribe(ExFinance.PubSub, topic)
end
