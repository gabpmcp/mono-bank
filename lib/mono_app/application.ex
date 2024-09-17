defmodule MonoApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MonoAppWeb.Telemetry,
      # Inicia el Repo de Ecto
      MonoApp.Repo,
      {DNSCluster, query: Application.get_env(:mono_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MonoApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MonoApp.Finch},
      # Start a worker by calling: MonoApp.Worker.start_link(arg)
      # {MonoApp.Worker, arg},
      # Start to serve requests, typically the last entry
      MonoAppWeb.Endpoint,
      {DynamicSupervisor, strategy: :one_for_one, name: MonoApp.DynamicSupervisor},
      MonoApp.KafkaConnector
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MonoApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MonoAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
