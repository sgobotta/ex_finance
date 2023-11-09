defmodule Redis.Client do
  @moduledoc """
  Convenience module to perform Redis operations
  """
  alias Redis.Stream

  require Logger

  @doc """
  Given a key returns the stored value.
  """
  @spec get(binary) ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom | Redix.Error.t() | Redix.ConnectionError.t()}
  def get(key), do: Redix.command(:redix, ["GET", key])

  @doc """
  Given a key and a map as value, encodes and sets the value in the given key.
  """
  @spec set(binary, map) ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom | Redix.Error.t() | Redix.ConnectionError.t()}
  def set(key, value),
    do: Redix.command(:redix, ["SET", key, Jason.encode!(value)])

  @doc """
  Given a stream name and options, calls the redix module to fetch a stream in
  redis.
  """
  @spec fetch_stream(binary, keyword) :: {atom, binary}
  def fetch_stream(stream_name, opts) do
    opts = parse_opts(opts)

    fetch_stream(stream_name, opts[:command], opts[:count])
  end

  @spec fetch_stream(binary, binary, nil | binary) :: {atom, binary}
  def fetch_stream(stream_name, command, nil) do
    Redix.command(:redix, [command, stream_name, "+", "-"])
  end

  def fetch_stream(stream_name, command, count) do
    Redix.command(:redix, [command, stream_name, "+", "-", "COUNT", count])
  end

  @spec fetch_last_stream_entry(String.t()) ::
          {:ok, Stream.Entry.t()} | {:error, :stream_parse_error}
  def fetch_last_stream_entry(stream_name) do
    with {:ok, _entries} = reply <- fetch_reverse_range(stream_name, 1),
         {:ok, parsed_entries} <- parse_stream_reply(reply) do
      {:ok, hd(parsed_entries)}
    end
  end

  @spec fetch_history(binary, :all | binary | non_neg_integer()) ::
          {:ok, any} | {:error, :no_result}
  def fetch_history(stream_name, :all) do
    opts = parse_opts(command: :asc)

    Redix.command(:redix, [opts[:command], stream_name, "-", "+"])
    |> parse_stream_reply()
  end

  def fetch_history(stream_name, count) do
    opts = parse_opts(count: count, command: :desc)

    Redix.command(:redix, [
      opts[:command],
      stream_name,
      "+",
      "-",
      "COUNT",
      opts[:count]
    ])
    |> parse_stream_reply()
  end

  @spec fetch_reverse_range(binary, binary | non_neg_integer()) ::
          {:ok, binary} | {:error, :no_result}
  def fetch_reverse_range(stream_name, count),
    do: fetch_stream(stream_name, count: count, command: :desc)

  defp parse_opts(opts) do
    opts
    |> Keyword.put(:count, parse_count_opt(opts))
    |> Keyword.put(:command, parse_command_opt(opts))
  end

  @spec parse_command_opt(keyword) :: binary
  defp parse_command_opt(opts) do
    case Keyword.get(opts, :command, :asc) == :asc do
      true ->
        "XRANGE"

      false ->
        "XREVRANGE"
    end
  end

  @spec parse_count_opt(keyword) :: integer | nil
  defp parse_count_opt(opts) do
    case Keyword.get(opts, :count, "*") do
      "*" ->
        nil

      count when is_integer(count) ->
        Integer.to_string(count)

      count when is_binary(count) ->
        count
    end
  end

  @spec parse_reply({atom, list | binary} | any) ::
          {:error, :no_result} | {:ok, any} | any
  defp parse_reply({:ok, []}), do: {:error, :no_result}
  defp parse_reply({:ok, _result} = result), do: result

  defp parse_stream_reply(reply) do
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

  def parse_stream_entry([_entry_id, _entry_values] = entry),
    do: Stream.Entry.from_raw_entry(entry)

  @spec parse_stream_entries([any()]) :: [map()]
  defp parse_stream_entries(entries),
    do: entries |> Enum.map(&parse_stream_entry/1)
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
  @spec from_raw_entry(any()) :: map()
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
