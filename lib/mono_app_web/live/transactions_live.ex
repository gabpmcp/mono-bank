defmodule BankAppWeb.TransactionsLive do
  use Phoenix.LiveView

  alias MonoApp.Accounts.Transactions

  # La función mount es donde inicializamos el estado del LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: :ok

    # Inicializamos el estado de la lista de transacciones
    {:ok, assign(socket, transactions: Transactions.list_transactions())}
  end

  # Puedes manejar eventos en tiempo real como "phx-click"
  def handle_event("refresh", _params, socket) do
    # Al manejar el evento "refresh", actualizamos las transacciones
    {:noreply, assign(socket, transactions: Transactions.list_transactions())}
  end
end
