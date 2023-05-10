defmodule BrokerApplication do
  use Application

  def start(_type, _args) do
    :ets.new(:app, [:named_table, :set, :public])

    {_resp, pid}= BrokerSupervisor.start_link([])
  end
end
