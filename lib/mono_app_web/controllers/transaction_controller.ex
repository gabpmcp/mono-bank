defmodule MonoAppWeb.TransactionController do
  use MonoAppWeb, :controller
  alias MonoApp.Accounts.Transactions

  action_fallback(MonoAppWeb.FallbackController)

  def create(conn, %{"transaction" => transaction_params}) do
    case Transactions.create_transaction(transaction_params) do
      {:ok, transaction} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Transaction created", transaction: transaction})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset})
    end
  end
end
