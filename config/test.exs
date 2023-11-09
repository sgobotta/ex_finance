import Config

config :ex_finance, :environment, :test

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ex_finance, ExFinance.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ex_finance_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_finance, ExFinanceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "Qq1hY6YZZtkwOJipXEt+1N2Wh9SMVMtxHpMEYsV/VsOu/1i9cIKjL9sIZGWHjlUB",
  server: false

# In test we don't send emails.
config :ex_finance, ExFinance.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
