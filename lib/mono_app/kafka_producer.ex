defmodule MonoApp.KafkaProducer do
  use GenServer
  alias KafkaEx

  def start_link(_args) do
    GenServer.start_link(
      __MODULE__,
      %{connection_status: :disconnected, messages_sent: 0, messages_failed: 0},
      name: __MODULE__
    )
  end

  @impl true
  def init(state) do
    # Aquí podrías inicializar una conexión a Kafka
    {:ok, %{state | connection_status: :connected}}
  end

  def produce_event(topic, key, value) do
    # Llama a GenServer para producir un evento de manera asíncrona
    GenServer.cast(__MODULE__, {:produce, topic, key, value})
  end

  defp calculate_backoff(retries) do
    # Backoff exponencial
    :timer.seconds(2 * (5 - retries))
  end

  @impl true
  def handle_cast({:produce, topic, key, value, retries}, state) do
    case KafkaEx.produce(topic, :undefined, value, key: key) do
      :ok ->
        IO.puts("Mensaje producido correctamente en #{topic} para #{key}: #{value}")
        # Actualizar el estado incrementando el contador de mensajes enviados
        new_state = %{state | messages_sent: state.messages_sent + 1}
        {:noreply, new_state}

      {:error, reason} ->
        # Podrías intentar reconectar o manejar el error internamente
        IO.puts("Error al producir mensaje: #{reason}, reintentando...")
        # Reintenta con un número decreciente de intentos y un retraso (backoff exponencial)
        Process.send_after(
          self(),
          {:produce_event, topic, key, value, retries - 1},
          calculate_backoff(retries)
        )

        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:produce_event, topic, key, value, 0}, state) do
    # Si se agotaron los reintentos, loguear el fallo y abandonar
    IO.puts(
      "Error definitivo: No se pudo producir el mensaje en #{topic} para #{key}: #{value} después de múltiples intentos."
    )

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    # Cerrar conexión de Kafka
    case KafkaEx.stop(state.connection_pid) do
      :ok -> IO.puts("Conexión a Kafka cerrada correctamente.")
      {:error, reason} -> IO.puts("Error al cerrar la conexión: #{reason}")
    end

    :ok
  end
end
