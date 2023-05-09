defmodule PublisherSupervisor do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__,[], name: __MODULE__)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)
    :ets.new(:app, [:named_table, :set, :public])
    {:ok, socket} = :gen_tcp.listen(5000, [:binary, packet: :line, active: false, reuseaddr: true])
    :ets.insert(:app, {:pub_socket, socket})
    DynamicSupervisor.init(strategy:  :one_for_one, max_restarts: 2000)
  end


end
