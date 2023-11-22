defmodule ExFinanceWeb.Utils.DatetimeUtils do
  @moduledoc false
  def human_readable_datetime(datetime), do: parse_datetime(datetime)

  def human_readable_datetime(datetime, :shift_timezone) do
    {:ok, datetime} = DateTime.shift_zone(datetime, timezone())
    parse_datetime(datetime)
  end

  defp parse_datetime(datetime) do
    hour = maybe_fill_datetime_value(datetime.hour)
    minute = maybe_fill_datetime_value(datetime.minute)
    "#{datetime.day}/#{datetime.month}/#{datetime.year} - #{hour}:#{minute}hs"
  end

  defp maybe_fill_datetime_value(value),
    do: if(value < 10, do: "0#{value}", else: "#{value}")

  def timezone, do: System.get_env("TZ", "America/Buenos_Aires")
end
