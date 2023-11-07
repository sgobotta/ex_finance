defmodule ExFinance.Seeds.Prod do
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
    :ok = Logger.info("🌱 Finished seeds creation for prod environment.")

    :ok
  end
end
