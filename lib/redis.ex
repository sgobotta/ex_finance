defmodule Redis do
  @moduledoc """
  Wrapper module for the Redix dep.
  """

  @type redix_response ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}

  defdelegate child_spec(opts), to: Redis.Application
end
