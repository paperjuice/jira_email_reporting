defmodule EmailReport.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Adapters.Cowboy2, scheme: :http, plug: EmailReport.Router, options: [port: 9999]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
