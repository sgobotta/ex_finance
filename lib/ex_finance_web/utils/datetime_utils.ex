defmodule ExFinanceWeb.Utils.DatetimeUtils do
  @moduledoc false

  @spec human_readable_datetime(DateTime.t(), Keyword.t()) :: String.t()
  def human_readable_datetime(datetime, opts \\ []) do
    if opts[:shift_timezone] do
      {:ok, datetime} = DateTime.shift_zone(datetime, timezone())
      parse_datetime(datetime, opts)
    else
      parse_datetime(datetime, opts)
    end
  end

  @spec parse_datetime(DateTime.t(), Keyword.t()) :: String.t()
  defp parse_datetime(datetime, opts) do
    if opts[:only_date] do
      parse_date(datetime)
    else
      parse_full_datetime(datetime)
    end
  end

  @spec parse_date(DateTime.t()) :: String.t()
  defp parse_date(datetime) do
    "#{datetime.day}/#{datetime.month}/#{datetime.year}"
  end

  @spec parse_time(DateTime.t()) :: String.t()
  defp parse_time(datetime) do
    hour = maybe_fill_datetime_value(datetime.hour)
    minute = maybe_fill_datetime_value(datetime.minute)
    "#{hour}:#{minute}"
  end

  @spec maybe_fill_datetime_value(integer()) :: String.t()
  defp maybe_fill_datetime_value(value),
    do: if(value < 10, do: "0#{value}", else: "#{value}")

  @spec parse_full_datetime(DateTime.t()) :: String.t()
  defp parse_full_datetime(datetime) do
    date = parse_date(datetime)
    time = parse_time(datetime)
    "#{date} #{time}"
  end

  @spec timezone() :: String.t()
  def timezone, do: System.get_env("TZ", "America/Buenos_Aires")
end
