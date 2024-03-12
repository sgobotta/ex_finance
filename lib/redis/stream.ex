defmodule Redis.Stream do
  @moduledoc """
  Module definition for redis streams
  """

  alias Redis.Client
  alias Redis.Stream

  require Logger

  @type since :: binary() | non_neg_integer()
  @type until :: binary() | non_neg_integer()
  @type response :: {:ok, [Stream.Entry.t()]} | {:error, :stream_parse_error}

  @spec xrevrange(binary(), since(), until()) :: response()
  def xrevrange(stream_name, until \\ "+", since \\ "-") do
    Redix.command(:redix, ["XREVRANGE", stream_name, since, until])
    |> parse_response()
  end

  @spec parse_response(Client.redix_response()) ::
          {:ok, [map()]} | {:error, :stream_parse_error}
  defp parse_response(reply) do
    with {:ok, entries} <- parse_reply(reply),
         parsed_entries <- parse_stream_entries(entries) do
      {:ok, parsed_entries}
    end
  rescue
    error ->
      Logger.error(
        "There was an error while processing the stream result error=#{inspect(error)}"
      )

      {:error, :stream_parse_error}
  end

  @spec parse_reply({atom, list | binary} | any) ::
          {:error, :no_result} | {:ok, any} | any
  defp parse_reply({:ok, []}), do: {:error, :no_result}
  defp parse_reply({:ok, _result} = result), do: result

  @spec parse_stream_entries([any()]) :: [Stream.Entry.t()]
  defp parse_stream_entries(entries),
    do: entries |> Enum.map(&parse_stream_entry/1)

  @spec parse_stream_entry(list()) :: Stream.Entry.t()
  defp parse_stream_entry([_entry_id, _entry_values] = entry),
    do: Stream.Entry.from_raw_entry(entry)
end

defmodule Redis.Stream.Entry do
  @moduledoc false
  require Integer

  @enforce_keys [:id, :values, :datetime]
  defstruct id: nil, values: nil, datetime: nil

  @type t :: %__MODULE__{}

  @doc """
  Given a redis stream entry returns a readable map representation of the
  entry values.
  """
  @spec from_raw_entry(any()) :: t()
  def from_raw_entry([entry_id, entry]) do
    datetime = parse_stream_entry_id(entry_id)

    Enum.reduce(Enum.with_index(entry), {[], []}, fn {value, index},
                                                     {keys, values} ->
      case Integer.is_even(index) do
        true ->
          {keys ++ [value], values}

        false ->
          {keys, values ++ [value]}
      end
    end)
    |> then(fn {keys, values} -> Enum.zip(keys, values) end)
    |> Enum.into(%{})
    |> then(fn values ->
      %__MODULE__{id: entry_id, values: values, datetime: datetime}
    end)
  end

  @spec parse_stream_entry_id(String.t()) :: DateTime.t()
  defp parse_stream_entry_id(entry_id) do
    entry_id
    |> String.split("-")
    |> hd
    |> String.to_integer()
    |> DateTime.from_unix!(:millisecond)
  end
end
