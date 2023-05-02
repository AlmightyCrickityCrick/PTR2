defmodule PubSub do
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)

    children = [
      Supervisor.child_spec({Register, []}, id: :register, restart: :permanent),
      Supervisor.child_spec({PublisherSupervisor, []}, id: :pub_sup, restart: :permanent),
    ]

    Supervisor.init(children, [strategy: :one_for_one, max_restarts: 200])

  end
end
