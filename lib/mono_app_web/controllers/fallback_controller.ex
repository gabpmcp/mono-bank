defmodule MonoAppWeb.FallbackController do
  use MonoAppWeb, :controller

  def call(conn, {:error, :bad_request, params}) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Transaction data not provided or is incorrect",
      received: params,
      example: %{
        "transaction" => %{
          "amount" => 100,
          "description" => "Payment",
          "transaction_type" => "debit | credit",
          "user_id" => "user"
        }
      }
    })
  end
end
