defmodule Producer do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom("producer#{args}"))
  end

  def init(args) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4000, [:binary, packet: :line, active: false])
    Process.sleep(100)
    resp = :gen_tcp.send(socket, "type: producer, action: register, name: #{"producer#{args}"}\n")
    # resp = :gen_tcp.close(socket)

    {:ok, %{name: String.to_atom("producer#{args}")}}
  end



end
