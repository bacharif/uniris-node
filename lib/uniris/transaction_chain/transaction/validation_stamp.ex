defmodule Uniris.TransactionChain.Transaction.ValidationStamp do
  @moduledoc """
  Represents a validation stamp created by a coordinator on a pending transaction
  """

  alias Uniris.Crypto

  alias __MODULE__.LedgerOperations

  defstruct [
    :signature,
    :proof_of_work,
    :proof_of_integrity,
    ledger_operations: %LedgerOperations{},
    recipients: [],
    contract_validation: true
  ]

  @typedoc """
  Validation performed by a coordinator:
  - Proof of work: Origin public key matching the origin signature
  - Proof of integrity: Integrity proof from the entire transaction chain
  - Ledger Operations: Set of ledger operations taken by the network such as fee, node movements, transaction movements and unspent outputs
  - Recipients: List of the last smart contract chain resolved addresses
  - Contract validation: Determine if the transaction coming from a contract is valid according to the constraints
  - Signature: generated from the coordinator private key to avoid non-repudiation of the stamp
  """
  @type t :: %__MODULE__{
          signature: nil | binary(),
          proof_of_work: Crypto.key(),
          proof_of_integrity: Crypto.versioned_hash(),
          ledger_operations: LedgerOperations.t(),
          recipients: list(Crypto.versioned_hash()),
          contract_validation: boolean()
        }

  @spec sign(__MODULE__.t()) :: __MODULE__.t()
  def sign(stamp = %__MODULE__{}) do
    sig =
      stamp
      |> extract_for_signature()
      |> serialize()
      |> Crypto.sign_with_node_key()

    %{stamp | signature: sig}
  end

  @doc """
  Extract fields to prepare serialization for the signature
  """
  @spec extract_for_signature(__MODULE__.t()) :: __MODULE__.t()
  def extract_for_signature(%__MODULE__{
        proof_of_work: pow,
        proof_of_integrity: poi,
        ledger_operations: ops,
        recipients: recipients,
        contract_validation: contract_validation
      }) do
    %__MODULE__{
      proof_of_work: pow,
      proof_of_integrity: poi,
      ledger_operations: ops,
      recipients: recipients,
      contract_validation: contract_validation
    }
  end

  @doc """
  Serialize a validation stamp info binary format

  ## Examples

      iex> %ValidationStamp{
      ...>   proof_of_work: <<0, 34, 248, 200, 166, 69, 102, 246, 46, 84, 7, 6, 84, 66, 27, 8, 78, 103, 37,
      ...>     155, 114, 208, 205, 40, 44, 6, 159, 178, 5, 186, 168, 237, 206>>,
      ...>   proof_of_integrity: <<0, 49, 174, 251, 208, 41, 135, 147, 199, 114, 232, 140, 254, 103, 186, 138, 175,
      ...>     28, 156, 201, 30, 100, 75, 172, 95, 135, 167, 180, 242, 16, 74, 87, 170>>,
      ...>   ledger_operations: %LedgerOperations{
      ...>      fee: 0.1, 
      ...>      transaction_movements: [], 
      ...>      node_movements: [], 
      ...>      unspent_outputs: []
      ...>   },
      ...>   signature: <<67, 12, 4, 246, 155, 34, 32, 108, 195, 54, 139, 8, 77, 152, 5, 55, 233, 217,
      ...>     126, 181, 204, 195, 215, 239, 124, 186, 99, 187, 251, 243, 201, 6, 122, 65,
      ...>     238, 221, 14, 89, 120, 225, 39, 33, 95, 95, 225, 113, 143, 200, 47, 96, 239,
      ...>     66, 182, 168, 35, 129, 240, 35, 183, 47, 69, 154, 37, 172>>
      ...> }
      ...> |> ValidationStamp.serialize()
      <<
      # Flag if the proof of work is founded
      1::1,
      # Proof of work
      0, 34, 248, 200, 166, 69, 102, 246, 46, 84, 7, 6, 84, 66, 27, 8, 78, 103, 37,
      155, 114, 208, 205, 40, 44, 6, 159, 178, 5, 186, 168, 237, 206,
      # Proof of integrity
      0, 49, 174, 251, 208, 41, 135, 147, 199, 114, 232, 140, 254, 103, 186, 138, 175,
      28, 156, 201, 30, 100, 75, 172, 95, 135, 167, 180, 242, 16, 74, 87, 170,
      # Fee
      63, 185, 153, 153, 153, 153, 153, 154,
      # Nb of transaction movements
      0,
      # Nb of node movements
      0,
      # Nb of unspent outputs
      0,
      # Nb of resolved recipients addresses,
      0,
      # Contract validation,
      1::1,
      # Signature size,
      64,
      # Signature
      67, 12, 4, 246, 155, 34, 32, 108, 195, 54, 139, 8, 77, 152, 5, 55, 233, 217,
      126, 181, 204, 195, 215, 239, 124, 186, 99, 187, 251, 243, 201, 6, 122, 65,
      238, 221, 14, 89, 120, 225, 39, 33, 95, 95, 225, 113, 143, 200, 47, 96, 239,
      66, 182, 168, 35, 129, 240, 35, 183, 47, 69, 154, 37, 172
      >>
  """
  @spec serialize(__MODULE__.t()) :: bitstring()
  def serialize(%__MODULE__{
        proof_of_work: pow,
        proof_of_integrity: poi,
        ledger_operations: ledger_operations,
        recipients: recipients,
        contract_validation: contract_validation,
        signature: nil
      }) do
    pow_bitstring = if pow, do: 1, else: 0
    contract_validation = if contract_validation, do: 1, else: 0

    <<pow_bitstring::1, pow::binary, poi::binary,
      LedgerOperations.serialize(ledger_operations)::binary, length(recipients)::8,
      :erlang.list_to_binary(recipients)::binary, contract_validation::1>>
  end

  def serialize(%__MODULE__{
        proof_of_work: pow,
        proof_of_integrity: poi,
        ledger_operations: ledger_operations,
        recipients: recipients,
        contract_validation: contract_validation,
        signature: signature
      }) do
    pow_bitstring = if pow, do: 1, else: 0
    contract_validation = if contract_validation, do: 1, else: 0

    <<pow_bitstring::1, pow::binary, poi::binary,
      LedgerOperations.serialize(ledger_operations)::binary, length(recipients)::8,
      :erlang.list_to_binary(recipients)::binary, contract_validation::1, byte_size(signature)::8,
      signature::binary>>
  end

  @doc """
  Deserialize an encoded validation stamp

  ## Examples

      iex> <<1::1, 0, 34, 248, 200, 166, 69, 102, 246, 46, 84, 7, 6, 84, 66, 27, 8, 78, 103, 37,
      ...> 155, 114, 208, 205, 40, 44, 6, 159, 178, 5, 186, 168, 237, 206,
      ...> 0, 49, 174, 251, 208, 41, 135, 147, 199, 114, 232, 140, 254, 103, 186, 138, 175,
      ...> 28, 156, 201, 30, 100, 75, 172, 95, 135, 167, 180, 242, 16, 74, 87, 170,
      ...> 63, 185, 153, 153, 153, 153, 153, 154, 0, 0, 0, 0, 1::1, 64,
      ...> 67, 12, 4, 246, 155, 34, 32, 108, 195, 54, 139, 8, 77, 152, 5, 55, 233, 217,
      ...> 126, 181, 204, 195, 215, 239, 124, 186, 99, 187, 251, 243, 201, 6, 122, 65,
      ...> 238, 221, 14, 89, 120, 225, 39, 33, 95, 95, 225, 113, 143, 200, 47, 96, 239,
      ...> 66, 182, 168, 35, 129, 240, 35, 183, 47, 69, 154, 37, 172>>
      ...> |> ValidationStamp.deserialize()
      {
        %ValidationStamp{
          proof_of_work: <<0, 34, 248, 200, 166, 69, 102, 246, 46, 84, 7, 6, 84, 66, 27, 8, 78, 103, 37,
            155, 114, 208, 205, 40, 44, 6, 159, 178, 5, 186, 168, 237, 206,>>,
          proof_of_integrity: << 0, 49, 174, 251, 208, 41, 135, 147, 199, 114, 232, 140, 254, 103, 186, 138, 175,
            28, 156, 201, 30, 100, 75, 172, 95, 135, 167, 180, 242, 16, 74, 87, 170>>,
          ledger_operations: %ValidationStamp.LedgerOperations{
            fee: 0.1,
            transaction_movements: [],
            node_movements: [],
            unspent_outputs: []
          },
          recipients: [],
          contract_validation: true,
          signature: <<67, 12, 4, 246, 155, 34, 32, 108, 195, 54, 139, 8, 77, 152, 5, 55, 233, 217,
            126, 181, 204, 195, 215, 239, 124, 186, 99, 187, 251, 243, 201, 6, 122, 65,
            238, 221, 14, 89, 120, 225, 39, 33, 95, 95, 225, 113, 143, 200, 47, 96, 239,
            66, 182, 168, 35, 129, 240, 35, 183, 47, 69, 154, 37, 172>>
        },
        ""
      }
  """
  def deserialize(<<origin_sig_ok::1, rest::bitstring>>) do
    {pow, rest} =
      case origin_sig_ok do
        0 ->
          <<""::binary, rest::bitstring>> = rest
          {"", rest}

        1 ->
          <<curve_id::8, rest::bitstring>> = rest
          key_size = Crypto.key_size(curve_id)
          <<key::binary-size(key_size), rest::bitstring>> = rest
          {<<curve_id::8>> <> key, rest}
      end

    <<hash_id::8, rest::bitstring>> = rest
    hash_size = Crypto.hash_size(hash_id)
    <<hash::binary-size(hash_size), rest::bitstring>> = rest

    {ledger_ops, <<recipients_length::8, rest::bitstring>>} = LedgerOperations.deserialize(rest)

    {recipients, <<contract_validation::1, rest::bitstring>>} =
      deserialize_list_of_recipients_addresses(rest, recipients_length, [])

    contract_validation = if contract_validation == 1, do: true, else: false

    <<signature_size::8, signature::binary-size(signature_size), rest::bitstring>> = rest

    {
      %__MODULE__{
        proof_of_work: pow,
        proof_of_integrity: <<hash_id::8>> <> hash,
        ledger_operations: ledger_ops,
        recipients: recipients,
        contract_validation: contract_validation,
        signature: signature
      },
      rest
    }
  end

  @spec from_map(map()) :: __MODULE__.t()
  def from_map(stamp = %{}) do
    %__MODULE__{
      proof_of_work: Map.get(stamp, :proof_of_work),
      proof_of_integrity: Map.get(stamp, :proof_of_integrity),
      ledger_operations:
        Map.get(stamp, :ledger_operations, %LedgerOperations{}) |> LedgerOperations.from_map(),
      recipients: Map.get(stamp, :recipients, []),
      signature: Map.get(stamp, :signature)
    }
  end

  @spec to_map(__MODULE__.t()) :: map()
  def to_map(%__MODULE__{
        proof_of_work: pow,
        proof_of_integrity: poi,
        ledger_operations: ledger_operations,
        recipients: recipients,
        signature: signature
      }) do
    %{
      proof_of_work: pow,
      proof_of_integrity: poi,
      ledger_operations: LedgerOperations.to_map(ledger_operations),
      recipients: recipients,
      signature: signature
    }
  end

  @doc """
  Determine if the validation stamp signature is valid
  """
  @spec valid_signature?(__MODULE__.t(), Crypto.key()) :: boolean()
  def valid_signature?(%__MODULE__{signature: nil}, _public_key), do: false

  def valid_signature?(stamp = %__MODULE__{signature: signature}, public_key)
      when is_binary(signature) do
    raw_stamp =
      stamp
      |> extract_for_signature
      |> serialize

    Crypto.verify(signature, raw_stamp, public_key)
  end

  defp deserialize_list_of_recipients_addresses(rest, 0, _acc), do: {[], rest}

  defp deserialize_list_of_recipients_addresses(rest, nb_recipients, acc)
       when length(acc) == nb_recipients do
    {Enum.reverse(acc), rest}
  end

  defp deserialize_list_of_recipients_addresses(
         <<hash_id::8, rest::bitstring>>,
         nb_recipients,
         acc
       ) do
    hash_size = Crypto.hash_size(hash_id)
    <<hash::binary-size(hash_size), rest::bitstring>> = rest

    deserialize_list_of_recipients_addresses(rest, nb_recipients, [
      <<hash_id::8, hash::binary>> | acc
    ])
  end
end
