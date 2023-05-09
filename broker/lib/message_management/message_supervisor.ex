defmodule MessageSupervisor do
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)

    children = [
      Supervisor.child_spec({MessageRouter, []}, id: :mess_router, restart: :permanent),
      Supervisor.child_spec({DeadLetter, []}, id: :dead_letter, restart: :permanent),

    ]

    Supervisor.init(children, [strategy: :one_for_one, max_restarts: 200])

  end

end
