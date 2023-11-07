defmodule ExFinance.Seeds.Dev do
  @moduledoc """
  Runs development fixtures.
  """

  require Logger

  @spec populate :: :ok
  def populate do
    # Removes debug messages in this run
    :ok = Logger.configure(level: :info)

    :ok = Logger.info("📌 Starting seeds population process...")

    # Run seeds here
    :ok = Logger.info("🌱 Finished seeds creation for dev environment.")

    :ok
  end
end
