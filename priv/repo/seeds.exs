# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ExFinance.Repo.insert!(%ExFinance.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

:ok =
  System.fetch_env!("MIX_ENV")
  |> String.to_atom()
  |> ExFinance.Seeds.populate()
