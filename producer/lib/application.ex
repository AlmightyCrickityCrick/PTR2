defmodule ProducerApplication do
  use Application

  def start(_type, _args) do
        {_resp, pid}= ProducerSupervisor.start_link([])

  end
end
