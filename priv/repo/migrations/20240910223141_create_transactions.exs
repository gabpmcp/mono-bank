defmodule MonoApp.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  defmodule MonoApp.Repo.Migrations.CreateUsersAndTransactions do
    use Ecto.Migration

    def change do
      # Crear la tabla de usuarios
      create table(:users) do
        add(:name, :string, null: false)
        add(:email, :string, null: false, unique: true)
        add(:balance, :decimal, null: false, default: 0.0)

        timestamps()
      end

      # Crear un índice único en el email para garantizar que no haya duplicados
      create(unique_index(:users, [:email]))

      # Crear la tabla de transacciones
      create table(:transactions) do
        add(:amount, :decimal, null: false)
        add(:description, :string, null: false)
        add(:transaction_type, :string, null: false)
        add(:user_id, references(:users, on_delete: :nothing), null: false)

        timestamps()
      end

      # Crear un índice en user_id para optimizar consultas
      create(index(:transactions, [:user_id]))
    end
  end
end
