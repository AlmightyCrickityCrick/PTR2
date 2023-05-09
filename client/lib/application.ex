defmodule ClientApplication do
  use Application

  def start(_type, _args) do
        {_resp, pid}= ClientSupervisor.start_link([])

  end
end
