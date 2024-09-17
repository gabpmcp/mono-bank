defmodule MonoApp.Accounts.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias MonoApp.Repo

  schema "transactions" do
    field(:amount, :decimal)
    field(:description, :string)
    field(:transaction_type, :string)
    belongs_to(:user, BankApp.User)

    timestamps()
  end

  @doc """
  Crea un changeset para la transacción con validaciones.
  """
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :description, :transaction_type, :user_id])
    |> validate_required([:amount, :description, :transaction_type, :user_id])
    # Asegurarse de que el monto no sea cero
    |> validate_number(:amount, not_equal_to: 0)
    |> validate_inclusion(:transaction_type, ["credit", "debit"],
      message: "Transaction type should be equals to credit or debit!"
    )
    |> ensure_valid_balance
  end

  # Validación personalizada que asegura que una transacción de débito no deje la cuenta en saldo negativo
  def ensure_valid_balance(changeset, get_user_fn \\ &Repo.get/2) do
    with user_id <- get_field(changeset, :user_id),
         true <- get_field(changeset, :transaction_type) == "debit",
         user when not is_nil(user) <- get_user_fn.(User, user_id),
         new_balance when new_balance >= 0 <- user.balance - get_field(changeset, :amount) do
      changeset
    else
      nil ->
        add_error(changeset, :user_id, "User not found!")

      false ->
        changeset

      new_balance when new_balance < 0 ->
        add_error(changeset, :amount, "Insufficient funds in balance!")
    end
  end
end
