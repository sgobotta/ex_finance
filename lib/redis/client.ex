defmodule Redis.Client do
  @moduledoc """
  Convenience module to perform Redis operations
  """
  alias Redis.Stream

  require Logger

  @type redix_response ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom | Redix.Error.t() | Redix.ConnectionError.t()}

  @doc """
  Given a key returns the stored value.
  """
  @spec get(binary) :: redix_response()
  def get(key), do: Redix.command(:redix, ["GET", key])

  @doc """
  Given a key and a map as value, encodes and sets the value in the given key.
  """
  @spec set(binary, map) :: redix_response()
  def set(key, value),
    do: Redix.command(:redix, ["SET", key, Jason.encode!(value)])

  @doc """
  Given a stream name and a map, adds a new entry to the stream.
  """
  @spec xadd(binary, map) ::
          {:ok, Redix.Protocol.redis_value()} | {:error, :redis_xadd_error}
  def xadd(stream_name, entry) do
    Redix.command(
      :redix,
      [
        "XADD",
        stream_name,
        "*"
      ] ++ map_to_stream_values(entry)
    )
    |> parse_xadd_response()
  end

  @spec parse_xadd_response(redix_response()) ::
          {:ok, Redix.Protocol.redis_value()} | {:error, :redis_xadd_error}
  defp parse_xadd_response({:error, response}) do
    Logger.error(
      "An error occurred while trying to execute XADD command response=#{inspect(response)}"
    )

    {:error, :redis_xadd_error}
  end

  defp parse_xadd_response({:ok, _result} = response), do: response

  @doc """
  Given a stream name and options, calls the redix module to fetch a stream in
  redis.
  """
  @spec fetch_stream(binary, keyword) :: {atom, binary}
  def fetch_stream(stream_name, opts) do
    opts = parse_opts(opts)

    fetch_stream(stream_name, opts[:command], opts[:count])
  end

  @spec fetch_stream(binary, binary, nil | binary) :: redix_response()
  def fetch_stream(stream_name, command, nil) do
    Redix.command(:redix, [command, stream_name, "+", "-"])
  end

  def fetch_stream(stream_name, command, count) do
    Redix.command(:redix, [command, stream_name, "+", "-", "COUNT", count])
  end

  @spec fetch_reverse_stream_since(binary(), binary() | non_neg_integer()) ::
          Stream.response()
  def fetch_reverse_stream_since(stream_name, since),
    do: Stream.xrevrange(stream_name, "+", since)

  @spec fetch_last_stream_entry(String.t()) ::
          {:ok, Stream.Entry.t()}
          | {:error, :no_result | :stream_parse_error}
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

  @spec parse_opts(keyword) :: keyword
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

  @spec parse_stream_reply(redix_response()) ::
          {:ok, [map()]} | {:error, :stream_parse_error}
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

  @spec map_to_stream_values(map()) :: list(binary)
  defp map_to_stream_values(entry),
    do:
      Enum.reduce(entry, [], fn {key, value}, acc ->
        acc ++ [Atom.to_string(key), value]
      end)
end
