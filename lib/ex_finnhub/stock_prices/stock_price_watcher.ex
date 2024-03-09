defmodule ExFinnhub.StockPrices.StockPriceWatcher do
  @moduledoc false
  use Broadway

  alias Broadway.Message
  alias ExFinnhub.StockPrice
  alias ExFinnhub.StockPrices

  require Logger

  @spec child_spec(keyword()) :: map()
  def child_spec(supplier: supplier, module_name: module_name, symbol: symbol),
    do: %{
      id: supplier <> "-producer",
      start: {
        __MODULE__,
        :start_link,
        [
          [
            supplier: supplier,
            name: module_name,
            symbol: symbol
          ]
        ]
      },
      restart: :permanent,
      type: :worker
    }

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    supplier_name = Keyword.fetch!(opts, :supplier)
    symbol = Keyword.fetch!(opts, :symbol)

    Broadway.start_link(__MODULE__,
      name: name,
      producer: [
        module:
          {OffBroadwayRedisStream.Producer,
           [
             redis_client_opts: [
               host: Redis.Application.host!(),
               password: Redis.Application.password!()
             ],
             stream: get_stream(supplier_name, symbol),
             group: get_group(supplier_name),
             consumer_name: get_consumer_name(supplier_name),
             make_stream: true
           ]}
      ],
      processors: [
        default: [min_demand: 0, max_demand: 10]
      ]
    )
  end

  def handle_message(_processor, %Broadway.Message{} = message, _context) do
    Logger.debug("Loading stock price from message=#{inspect(message)}")

    with %Redis.Stream.Entry{} = entry <-
           Redis.Client.parse_stream_entry(message.data),
         {:ok, :loaded, %StockPrice{symbol: symbol} = stock_price} <-
           load_stock_price_entry(entry),
         :ok <-
           StockPrices.Channels.broadcast_new_stock_price!(
             symbol,
             stock_price
           ) do
      message
    else
      error ->
        Logger.error(
          "Error while processing message=#{inspect(message)} error=#{inspect(error)}"
        )

        Message.failed(message, reason: inspect(error))
    end
  end

  @max_attempts 5

  def handle_failed(messages, _context) do
    for message <- messages do
      if message.metadata.attempt < @max_attempts do
        Broadway.Message.configure_ack(message, retry: true)
      else
        Logger.warn("Dropping stock price from message=#{inspect(message)}")
        [id, _] = message.data
        id
      end
    end
  end

  @spec hostname :: binary()
  defp hostname do
    {:ok, host} = :inet.gethostname()
    to_string(host)
  end

  @spec load_stock_price_entry(Redis.Stream.Entry.t()) ::
          {:ok, :loaded, StockPrice.t()}
  defp load_stock_price_entry(%Redis.Stream.Entry{} = stream_entry) do
    {:ok, :loaded, StockPrice.from_entry!(stream_entry)}
  end

  @spec get_group(binary()) :: binary()
  defp get_group(supplier_id),
    do: "#{get_stage()}-#{supplier_id}-processor-group"

  @spec get_consumer_name(binary()) :: binary()
  defp get_consumer_name(supplier_id), do: "#{supplier_id}-#{hostname()}"

  @spec get_stream(binary(), binary()) :: binary()
  defp get_stream(supplier_id, symbol),
    do: "#{get_stage()}_stream_#{symbol}_new-prices_#{supplier_id}_v1"

  @spec get_stage :: ExFinance.Application.stage()
  defp get_stage, do: ExFinance.Application.stage()
end
