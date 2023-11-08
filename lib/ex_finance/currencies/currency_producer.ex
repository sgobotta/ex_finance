defmodule ExFinance.Currencies.CurrencyProducer do
  @moduledoc false
  use Broadway

  require Logger

  def child_spec(supplier: supplier, module_name: module_name),
    do: %{
      id: supplier <> "-producer",
      start: {
        ExFinance.Currencies.CurrencyProducer,
        :start_link,
        [
          [
            supplier: supplier,
            id: module_name
          ]
        ]
      },
      restart: :permanent,
      type: :worker
    }

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    supplier_name = Keyword.fetch!(opts, :supplier)

    Broadway.start_link(__MODULE__,
      name: Module.concat(String.to_atom(id), __MODULE__),
      producer: [
        module:
          {OffBroadwayRedisStream.Producer,
           [
             redis_client_opts: [
               host: System.get_env("REDIS_HOST", "localhost"),
               password: System.get_env("REDIS_PASS", "123456")
             ],
             stream: get_stream(supplier_name),
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

  def handle_message(_processor, message, _context) do
    Logger.debug("Loading product from message=#{inspect(message)}")

    %Redis.Stream.Entry{} =
      entry = Redis.Client.parse_stream_entry(message.data)

    {:ok, :loaded, _product} = load_product(entry)

    message
  end

  @max_attempts 5

  def handle_failed(messages, _context) do
    for message <- messages do
      if message.metadata.attempt < @max_attempts do
        Broadway.Message.configure_ack(message, retry: true)
      else
        Logger.warn("Dropping product from message=#{inspect(message)}")
        [id, _] = message.data
        id
      end
    end
  end

  defp hostname do
    {:ok, host} = :inet.gethostname()
    to_string(host)
  end

  defp load_product(%Redis.Stream.Entry{values: values}) do
    {:ok, _product} =
      ExFinance.Currencies.load_currency(values["product_stream_key"])

    {:ok, :loaded, %{}}
  end

  defp get_group(supplier_id),
    do: "#{get_stage()}-#{supplier_id}-processor-group"

  defp get_consumer_name(supplier_id), do: "#{supplier_id}-#{hostname()}"

  defp get_stream(supplier_id),
    do: "#{get_stage()}_stream_new-currencies_#{supplier_id}_v1"

  defp get_stage, do: ExFinance.Application.stage()
end
