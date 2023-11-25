defmodule ExFinance.Instruments.Channels do
  @moduledoc false

  require Logger

  @type message :: atom() | {atom(), any()} | {atom(), binary(), any()}

  # ----------------------------------------------------------------------------
  # Topics
  #
  @cedears_topic "cedears"

  # ----------------------------------------------------------------------------
  # Events
  #
  @cedear_updated :cedear_updated

  @doc """
  Returns the #{@cedears_topic} topic.
  """
  @spec cedears_topic() :: binary()
  def cedears_topic, do: @cedears_topic

  @doc """
  Returns the message name for cedear updated events.
  """
  @spec cedear_updated() :: :cedear_updated
  def cedear_updated, do: @cedear_updated

  @doc """
  Broadcasts a #{@cedear_updated} message.
  """
  @spec broadcast_cedear_updated!(any()) :: :ok
  def broadcast_cedear_updated!(payload),
    do:
      broadcast!(
        cedears_topic(),
        {cedear_updated(), payload}
      )

  @spec broadcast!(binary(), message()) :: :ok
  defp broadcast!(topic, message),
    do: Phoenix.PubSub.broadcast!(ExFinance.PubSub, topic, message)
end
