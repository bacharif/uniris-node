defmodule Uniris.TransactionChain.TransactionData.NFTLedgerTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Uniris.TransactionChain.TransactionData.NFTLedger
  alias Uniris.TransactionChain.TransactionData.NFTLedger.Transfer

  doctest NFTLedger

  property "symmetric serialization/deserialization of NFT ledger" do
    check all(
            transfers <-
              StreamData.map_of(
                StreamData.binary(length: 32),
                {StreamData.binary(length: 32), StreamData.float(min: 0.0)}
              )
          ) do
      transfers =
        Enum.map(transfers, fn {nft, {to, amount}} ->
          %Transfer{
            nft: <<0::8>> <> nft,
            to: <<0::8>> <> to,
            amount: amount
          }
        end)

      {nft_ledger, _} =
        %NFTLedger{transfers: transfers}
        |> NFTLedger.serialize()
        |> NFTLedger.deserialize()

      assert nft_ledger.transfers == transfers
    end
  end
end
