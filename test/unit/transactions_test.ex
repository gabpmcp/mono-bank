defmodule BankApp.Unit.TransactionsTest do
  use ExUnit.Case, async: true
  alias BankApp.Transactions

  test "creates transaction successfully" do
    # Simular que Repo.insert/1 retorna un resultado exitoso
    insert_mock = fn _changeset -> {:ok, %Transaction{id: 1, amount: 100}} end

    # Simular la producción de eventos a Kafka sin enviar el evento realmente
    kafka_mock = fn _topic, _key, _value ->
      :ok
    end

    transaction_params = %{
      "amount" => 100,
      "description" => "Payment",
      "transaction_type" => "debit",
      "user_id" => "user"
    }

    assert {:ok, transaction} =
             Transactions.create_transaction(transaction_params, insert_mock, kafka_mock)

    assert transaction.id == 1
  end

  test "returns error on invalid transaction" do
    # Simular que Repo.insert/1 retorna un changeset con errores
    insert_mock = fn _changeset -> {:error, %Ecto.Changeset{}} end

    # Simular la producción de eventos a Kafka sin enviar el evento realmente
    kafka_mock = fn _topic, _key, _value ->
      :ok
    end

    transaction_params = %{"amount" => -100, "description" => "Invalid"}

    assert {:error, _changeset} =
             Transactions.create_transaction(transaction_params, insert_mock, kafka_mock)
  end
end
