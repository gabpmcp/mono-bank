defmodule MonoApp.Accounts.Transactions do
  alias MonoApp.{Repo, Accounts.Transaction, KafkaProducer}
  alias Jason

  def create_transaction(
        transaction_params,
        insert_transaction \\ &Repo.insert/1,
        producer \\ &KafkaProducer.produce_event/3
      ) do
    changeset = Transaction.changeset(%{}, transaction_params)

    case insert_transaction.(changeset) do
      {:ok, transaction} ->
        # Enviar evento a Kafka
        producer.(
          "transactions_topic",
          transaction.id,
          Jason.encode!(transaction)
        )

        {:ok, transaction}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def list_transactions() do
    [
      %{
        "amount" => 100,
        "description" => "Payment 1",
        "transaction_type" => "debit | credit",
        "user_id" => "user"
      },
      %{
        "amount" => 200,
        "description" => "Payment 2",
        "transaction_type" => "debit | credit",
        "user_id" => "user"
      },
      %{
        "amount" => 300,
        "description" => "Payment 3",
        "transaction_type" => "debit | credit",
        "user_id" => "user"
      }
    ]
  end
end
