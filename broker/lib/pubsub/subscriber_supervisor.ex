defmodule SubscriberSupervisor do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__,[], name: __MODULE__)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)
    {:ok, socket} = :gen_tcp.listen(6000, [:binary, packet: :line, active: false, reuseaddr: true])
    {:ok, mqtt_socket} = :gen_tcp.listen(7000, [:binary, packet: :line, active: false, reuseaddr: true])
    :ets.insert(:app, {:sub_socket, socket})
    :ets.insert(:app, {:mqtt_socket, mqtt_socket})
    DynamicSupervisor.init(strategy:  :one_for_one, max_restarts: 2000)
  end


end
