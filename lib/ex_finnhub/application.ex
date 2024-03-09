defmodule ExFinnhub.Application do
  @moduledoc """
  Application configuration for ExFinnhub
  """

  @doc """
  Returns the configured finnhub api_key
  """
  @spec fetch_finnhub_token! :: binary()
  def fetch_finnhub_token!,
    do: Keyword.fetch!(fetch_ex_finnhub_config!(), :api_key)

  defp fetch_ex_finnhub_config!,
    do: ExFinance.Application.fetch_finnhub_config!()
end
