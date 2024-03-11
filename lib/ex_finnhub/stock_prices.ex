defmodule ExFinnhub.StockPrices do
  @moduledoc false

  alias ExFinnhub.StockPrice
  alias ExFinnhub.StockPrices.{Channels, StockPriceServer, StockPriceSupervisor}

  require Logger

  @supplier "finnhub"

  defdelegate child_spec(init_arg), to: ExFinnhub.StockPrices.Supervisor

  @spec heartbeat(pid()) :: :ok
  def heartbeat(pid), do: StockPriceServer.heartbeat(pid)

  @spec subscribe_stock_price(binary()) ::
          {:ok, pid(), {StockPrice.t() | nil, non_neg_integer() | nil}}
  def subscribe_stock_price(stock_symbol) do
    maybe_start_stock_price_watcher(stock_symbol)
    Channels.subscribe_stock_prices_topic(stock_symbol)
    {:ok, pid} = maybe_start_stock_price_worker(stock_symbol)

    {:ok, millis_to_next_price_update} =
      StockPriceServer.get_interval_timeleft(pid)

    case fetch_last_registered_stock_price(stock_symbol) do
      {:ok, %StockPrice{} = stock_price} ->
        {:ok, pid, {stock_price, millis_to_next_price_update}}

      {:error, :no_result} ->
        {:ok, pid, {nil, millis_to_next_price_update}}
    end
  end

  @spec work(binary()) :: :ok | :error
  def work(symbol) do
    with {:ok, %ExFinnhub.StockPrice{} = stock_price} <-
           fetch_stock_price(symbol),
         {:ok, _response} <- register_new_stock_price(symbol, stock_price) do
      :ok
    else
      error ->
        Logger.error("An error occurred while fetching symbol=#{symbol}")
        error
    end
  end

  @spec fetch_stock_price(binary()) :: {:ok, ExFinnhub.StockPrice.t()} | :error
  def fetch_stock_price(symbol), do: ExFinnhub.StockPrice.quote(symbol)

  @spec maybe_start_stock_price_watcher(binary()) :: :ok
  defp maybe_start_stock_price_watcher(symbol) do
    case StockPriceSupervisor.start_watcher(symbol) do
      {:ok, watcher_pid} ->
        Logger.debug(
          "Watcher started for symbol=#{symbol} with pid=#{inspect(watcher_pid)}"
        )

      {:error, {:already_started, watcher_pid}} ->
        Logger.debug(
          "Noop. Watcher for symbol=#{symbol} is already running with pid=#{inspect(watcher_pid)}."
        )
    end
  end

  @spec maybe_start_stock_price_worker(binary()) :: {:ok, pid()}
  defp maybe_start_stock_price_worker(symbol) do
    case StockPriceSupervisor.get_child(symbol) do
      nil ->
        {:ok, _worker_pid} =
          StockPriceSupervisor.start_child(
            id: symbol,
            do_work: &__MODULE__.work/1
          )

      {worker_pid, _state} ->
        :ok = __MODULE__.heartbeat(worker_pid)
        {:ok, worker_pid}
    end
  end

  @spec register_new_stock_price(binary(), ExFinnhub.StockPrice.t()) ::
          {:ok, Redix.Protocol.redis_value()} | {:error, :redis_xadd_error}
  defp register_new_stock_price(symbol, %ExFinnhub.StockPrice{} = stock_price) do
    stream = get_stream(@supplier, symbol)
    Redis.Client.xadd(stream, Map.from_struct(stock_price))
  end

  defp get_stream(supplier_id, symbol),
    do: "#{get_stage()}_stream_#{symbol}_new-prices_#{supplier_id}_v1"

  defp get_stage, do: ExFinance.Application.stage()

  @spec fetch_last_registered_stock_price(binary()) ::
          {:ok, StockPrice.t()} | {:error, :no_result}
  defp fetch_last_registered_stock_price(symbol) do
    case Redis.Client.fetch_last_stream_entry(get_stream(@supplier, symbol)) do
      {:ok, %Redis.Stream.Entry{} = entry} ->
        Logger.debug("Found registered stock price entry for symbol=#{symbol}")
        {:ok, StockPrice.from_entry!(entry)}

      {:error, error} ->
        Logger.warn(
          "No registered stock price entry found for symbol=#{symbol} error=#{inspect(error)}"
        )

        {:error, :no_result}
    end
  end
end
