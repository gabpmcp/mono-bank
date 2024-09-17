defmodule BankApp.Unit.TransactionTest do
  use ExUnit.Case
  alias BankApp.Transaction

  test "ensure_valid_balance returns error when user is not found" do
    changeset = %Ecto.Changeset{
      valid?: true,
      changes: %{user_id: 1, amount: 100, transaction_type: "debit"}
    }

    # Inyectar una función que siempre devuelva nil (simulando que el usuario no se encuentra)
    get_user_fn = fn _, _ -> nil end

    result = Transaction.ensure_valid_balance(changeset, get_user_fn)

    assert result.errors[:user_id] == {"User not found", []}
  end

  test "ensure_valid_balance calculates new balance correctly" do
    changeset = %Ecto.Changeset{
      valid?: true,
      changes: %{user_id: 1, amount: 50, transaction_type: "debit"}
    }

    # Inyectar una función que devuelva un usuario con un saldo específico
    get_user_fn = fn _, _ -> %{balance: 100} end

    result = Transaction.ensure_valid_balance(changeset, get_user_fn)

    assert result.errors == []
  end
end
