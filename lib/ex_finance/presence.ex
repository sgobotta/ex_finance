defmodule ExFinance.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :ex_finance,
    pubsub_server: ExFinance.PubSub
end
