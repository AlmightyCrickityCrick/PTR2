defmodule PublisherSupervisor do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__,[], name: __MODULE__)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)
    DynamicSupervisor.init(strategy:  :one_for_one, max_restarts: 2000)
  end

end
