defmodule ExFinance.Currencies.Channels do
  @moduledoc false

  require Logger

  @type message :: atom() | {atom(), any()} | {atom(), binary(), any()}

  # ----------------------------------------------------------------------------
  # Topics
  #
  @currencies_topic "currencies"

  # ----------------------------------------------------------------------------
  # Events
  #
  @currency_updated :currency_updated

  @doc """
  Returns the #{@currencies_topic} topic.
  """
  @spec currencies_topic() :: binary()
  def currencies_topic, do: @currencies_topic

  @doc """
  Returns the message name for currency updated events.
  """
  @spec currency_updated() :: :currency_updated
  def currency_updated, do: @currency_updated

  @doc """
  Subscribes to the #{@currencies_topic} topic.
  """
  @spec subscribe_currencies_topic() :: :ok | {:error, any()}
  def subscribe_currencies_topic, do: subscribe(currencies_topic())

  @doc """
  Broadcasts a #{@currency_updated} message.
  """
  @spec broadcast_currency_updated!(any()) :: :ok
  def broadcast_currency_updated!(payload),
    do:
      broadcast!(
        currencies_topic(),
        {currency_updated(), payload}
      )

  @spec broadcast!(binary(), message()) :: :ok
  defp broadcast!(topic, message),
    do: Phoenix.PubSub.broadcast!(ExFinance.PubSub, topic, message)

  @spec subscribe(binary()) :: :ok | {:error, any()}
  defp subscribe(topic), do: Phoenix.PubSub.subscribe(ExFinance.PubSub, topic)
end
