defmodule ExFinnhub.Client do
  @moduledoc false

  @v1_base_url "https://finnhub.io/api/v1/"

  @spec get(String.t(), keyword(), keyword()) :: {:ok, map()} | :error
  def get(resource, headers \\ [], opts \\ []) do
    __MODULE__.build(:get, @v1_base_url <> resource, headers, nil, opts)
    |> Finch.request(ExFinance.Finch)
    |> parse_response()
  end

  defdelegate build(method, url, headers \\ [], body \\ nil, opts \\ []),
    to: Finch

  defp parse_response({:ok, %Finch.Response{body: body, status: status}})
       when status in 200..299 do
    {:ok, Jason.decode!(body)}
  end

  defp parse_response(_response), do: :error
end
