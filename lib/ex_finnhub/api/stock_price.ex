defmodule ExFinnhub.StockPrice do
  @moduledoc false

  @type t :: %__MODULE__{}

  defstruct current: Decimal.new(0),
            change: Decimal.new(0),
            percent_change: Decimal.new(0),
            high: Decimal.new(0),
            low: Decimal.new(0),
            open: Decimal.new(0),
            previous_close: Decimal.new(0),
            timestamp: nil

  @resource "quote"

  @doc """
  Given a symbol, fetches the current stock price to returns a `StockPrice`
  struct for the given stock.
  """
  @spec quote(String.t(), keyword()) :: {:ok, map()} | :error
  def quote(symbol, _opts \\ []) do
    symbol
    |> encode_query()
    |> build_client()
  end

  @spec build_client(binary()) :: {:ok, map()} | :error
  defp build_client(query) do
    case ExFinnhub.Client.get("#{@resource}?#{query}") do
      {:ok, stock_price} ->
        {:ok, parse_response(stock_price)}

      :error ->
        :error
    end
  end

  defp encode_query(symbol) do
    URI.encode_query(%{
      symbol: symbol,
      token: fetch_finnhub_token!()
    })
  end

  defp fetch_finnhub_token!, do: Application.fetch_env!(:ex_finnhub, :api_key)

  defp parse_response(%{
         "c" => current,
         "d" => change,
         "dp" => percent_change,
         "h" => high,
         "l" => low,
         "o" => open,
         "pc" => previous_close,
         "t" => timestamp
       }) do
    %__MODULE__{
      current: parse_number(current),
      change: parse_number(change),
      percent_change: parse_number(percent_change),
      high: parse_number(high),
      low: parse_number(low),
      open: parse_number(open),
      previous_close: parse_number(previous_close),
      timestamp: timestamp
    }
  end

  defp parse_number(n) when is_float(n), do: Decimal.from_float(n)
  defp parse_number(n), do: Decimal.new(n)
end
