defmodule ExFinanceWeb.Utils.DatetimeUtils do
  @moduledoc false
  def human_readable_datetime(datetime) do
    hour = maybe_fill_datetime_value(datetime.hour)
    minute = maybe_fill_datetime_value(datetime.minute)
    "#{datetime.day}/#{datetime.month}/#{datetime.year} - #{hour}:#{minute}"
  end

  defp maybe_fill_datetime_value(value),
    do: if(value < 10, do: "0#{value}", else: "#{value}")
end
