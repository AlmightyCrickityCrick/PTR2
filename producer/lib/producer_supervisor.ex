defmodule ProducerSupervisor do
  use Supervisor
  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)

    children = [
      Supervisor.child_spec({Producer, 1}, id: String.to_atom("p1"), restart: :permanent),
      # Supervisor.child_spec({Producer, 2}, id: String.to_atom("p2"), restart: :permanent),
    ]

    Supervisor.init(children, [strategy: :one_for_one, max_restarts: 200])
  end

end
