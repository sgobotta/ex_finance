defmodule Redis.Application do
  @moduledoc false

  def child_spec(_opts),
    do: Redix.child_spec(host: host!(), name: :redix, password: password!())

  def opts,
    do: [host: host!(), password: password!()]

  def host!, do: Keyword.fetch!(env(), :redis_host)
  def password!, do: Keyword.fetch!(env(), :redis_pass)
  def env, do: Application.fetch_env!(:ex_finance, Redis)
end
