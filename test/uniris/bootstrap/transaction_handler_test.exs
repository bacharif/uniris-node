defmodule Uniris.Bootstrap.TransactionHandlerTest do
  use UnirisCase

  @moduletag :capture_log

  alias Uniris.Bootstrap.TransactionHandler

  alias Uniris.P2P
  alias Uniris.P2P.Message.NewTransaction
  alias Uniris.P2P.Message.Ok
  alias Uniris.P2P.Message.SubscribeTransactionValidation

  alias Uniris.P2P.Node

  alias Uniris.TransactionChain.Transaction
  alias Uniris.TransactionChain.TransactionData

  alias Uniris.PubSub

  import Mox

  test "create_node_transaction/2 should create transaction with ip and port encoded in the content" do
    assert %Transaction{
             data: %TransactionData{
               content: """
               ip: 127.0.0.1
               port: 3000
               """
             }
           } = TransactionHandler.create_node_transaction({127, 0, 0, 1}, 3000)
  end

  test "send_transaction/2 should send the transaction to a welcome node" do
    node = %Node{
      ip: {80, 10, 101, 202},
      port: 4390,
      first_public_key: "key1",
      last_public_key: "key1",
      available?: true
    }

    :ok = P2P.add_node(node)

    MockTransport
    |> expect(:send_message, fn _, _, %NewTransaction{} ->
      {:ok, %Ok{}}
    end)

    tx = TransactionHandler.create_node_transaction({127, 0, 0, 1}, 3000)
    assert :ok = TransactionHandler.send_transaction(tx, node)
  end

  test "await_validation/1 should return :ok when the transaction is validated" do
    MockTransport
    |> stub(:send_message, fn _, _, %SubscribeTransactionValidation{address: address} ->
      PubSub.register_to_new_transaction_by_address(address)

      receive do
        {:new_transaction, ^address} ->
          {:ok, %Ok{}}
      end
    end)

    node = %Node{
      ip: {80, 10, 101, 202},
      port: 4390,
      first_public_key: "key1",
      last_public_key: "key1",
      available?: true
    }

    :ok = P2P.add_node(node)

    t = Task.async(fn -> TransactionHandler.await_validation("@Alice1", node) end)
    Process.sleep(500)
    PubSub.notify_new_transaction("@Alice1")

    assert :ok = Task.await(t)
  end
end
