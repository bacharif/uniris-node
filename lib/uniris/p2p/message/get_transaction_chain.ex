defmodule Uniris.P2P.Message.GetTransactionChain do
  @moduledoc """
  Represents a message to request an entire transaction chain
  """
  @enforce_keys [:address]
  defstruct [:address]

  alias Uniris.Crypto

  @type t :: %__MODULE__{
          address: Crypto.versioned_hash()
        }
end
